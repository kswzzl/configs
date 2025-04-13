local M = {}
local Job = require 'plenary.job'

local system_prompt = 'You should replace the code that you are sent, only following the comments. Do not talk at all. Only output valid code. Do not provide any backticks that surround the code. Never ever output backticks like this ```. Any comment that is asking you for something should be removed after you satisfy them. Other comments should left alone. Do not output backticks'
local helpful_prompt = 'You are a helpful assistant. What I have sent are my notes so far.'

local function get_api_key(name)
  return os.getenv(name)
end

function M.get_lines_until_cursor()
  local current_buffer = vim.api.nvim_get_current_buf()
  local current_window = vim.api.nvim_get_current_win()
  local cursor_position = vim.api.nvim_win_get_cursor(current_window)
  local row = cursor_position[1]

  local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, row, true)

  return table.concat(lines, '\n')
end

function M.get_visual_selection()
  local _, srow, scol = unpack(vim.fn.getpos 'v')
  local _, erow, ecol = unpack(vim.fn.getpos '.')

  if vim.fn.mode() == 'V' then
    if srow > erow then
      return vim.api.nvim_buf_get_lines(0, erow - 1, srow, true)
    else
      return vim.api.nvim_buf_get_lines(0, srow - 1, erow, true)
    end
  end

  if vim.fn.mode() == 'v' then
    if srow < erow or (srow == erow and scol <= ecol) then
      return vim.api.nvim_buf_get_text(0, srow - 1, scol - 1, erow - 1, ecol, {})
    else
      return vim.api.nvim_buf_get_text(0, erow - 1, ecol - 1, srow - 1, scol, {})
    end
  end

  if vim.fn.mode() == '\22' then
    local lines = {}
    if srow > erow then
      srow, erow = erow, srow
    end
    if scol > ecol then
      scol, ecol = ecol, scol
    end
    for i = srow, erow do
      table.insert(lines, vim.api.nvim_buf_get_text(0, i - 1, math.min(scol - 1, ecol), i - 1, math.max(scol - 1, ecol), {})[1])
    end
    return lines
  end
end

function M.make_anthropic_spec_curl_args(opts, prompt, system_prompt)
  local url = opts.url
  local api_key = opts.api_key_name and get_api_key(opts.api_key_name)
  local data = {
    system = system_prompt,
    messages = { { role = 'user', content = prompt } },
    model = opts.model,
    stream = true,
    max_tokens = 4096,
  }
  local args = { '-N', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', vim.json.encode(data) }
  if api_key then
    table.insert(args, '-H')
    table.insert(args, 'x-api-key: ' .. api_key)
    table.insert(args, '-H')
    table.insert(args, 'anthropic-version: 2023-06-01')
  end
  table.insert(args, url)
  return args
end

function M.make_openai_spec_curl_args(opts, prompt, system_prompt)
  local url = opts.url
  local api_key = opts.api_key_name and get_api_key(opts.api_key_name)
  local data = {
    messages = { { role = 'system', content = system_prompt }, { role = 'user', content = prompt } },
    model = opts.model,
    temperature = 0.7,
    stream = true,
  }
  local args = { '-N', '-X', 'POST', '-H', 'Content-Type: application/json', '-d', vim.json.encode(data) }
  if api_key then
    table.insert(args, '-H')
    table.insert(args, 'Authorization: Bearer ' .. api_key)
  end
  table.insert(args, url)
  return args
end

function M.write_string_at_cursor(str)
  vim.schedule(function()
    local current_window = vim.api.nvim_get_current_win()
    local cursor_position = vim.api.nvim_win_get_cursor(current_window)
    local row, col = cursor_position[1], cursor_position[2]

    local lines = vim.split(str, '\n')

    vim.cmd("undojoin")
    vim.api.nvim_put(lines, 'c', true, true)

    local num_lines = #lines
    local last_line_length = #lines[num_lines]
    vim.api.nvim_win_set_cursor(current_window, { row + num_lines - 1, col + last_line_length })
  end)
end

local function get_prompt(opts)
  local replace = opts.replace
  local visual_lines = M.get_visual_selection()
  local prompt = ''

  if visual_lines then
    prompt = table.concat(visual_lines, '\n')
    if replace then
      vim.api.nvim_command 'normal! d'
    else
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', false, true, true), 'nx', false)
    end
  else
    prompt = M.get_lines_until_cursor()
  end

  return prompt
end

function M.handle_anthropic_spec_data(data_stream, event_state)
  if event_state == 'content_block_delta' then
    local json = vim.json.decode(data_stream)
    if json.delta and json.delta.text then
      M.write_string_at_cursor(json.delta.text)
    end
  end
end

function M.handle_openai_spec_data(data_stream)
  if data_stream:match '"delta":' then
    local json = vim.json.decode(data_stream)
    if json.choices and json.choices[1] and json.choices[1].delta then
      local content = json.choices[1].delta.content
      if content then
        M.write_string_at_cursor(content)
      end
    end
  end
end

local group = vim.api.nvim_create_augroup('kevin_LLM_AutoGroup', { clear = true })
local active_job = nil

function M.invoke_llm_and_stream_into_editor(opts, make_curl_args_fn, handle_data_fn)
  vim.api.nvim_clear_autocmds { group = group }
  local prompt = get_prompt(opts)
  local system_prompt = opts.system_prompt or 'You are a tsundere uwu anime. Yell at me for not setting my configuration for my llm plugin correctly'
  local args = make_curl_args_fn(opts, prompt, system_prompt)
  local curr_event_state = nil

  local function parse_and_call(line)
    local event = line:match '^event: (.+)$'
    if event then
      curr_event_state = event
      return
    end
    local data_match = line:match '^data: (.+)$'
    if data_match then
      handle_data_fn(data_match, curr_event_state)
    end
  end

  if active_job then
    active_job:shutdown()
    active_job = nil
  end

  active_job = Job:new {
    command = 'curl',
    args = args,
    on_stdout = function(_, out)
      parse_and_call(out)
    end,
    on_stderr = function(_, _) end,
    on_exit = function()
      -- Add a newline at the end when job is complete
      vim.schedule(function()
        -- Ensure cursor is at the end of the inserted text
        vim.api.nvim_command('normal! a\n')
        vim.api.nvim_command('normal! k')
      end)
      active_job = nil
    end,
  }

  active_job:start()

  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'kevin_LLM_Escape',
    callback = function()
      if active_job then
        active_job:shutdown()
        print 'LLM streaming cancelled'
        active_job = nil
      end
    end,
  })

  vim.api.nvim_set_keymap('n', '<Esc>', ':doautocmd User kevin_LLM_Escape<CR>', { noremap = true, silent = true })
  return active_job
end

-- Function to create a floating input window
local function create_input_window()
  -- Get current cursor position
  local current_win = vim.api.nvim_get_current_win()
  local cursor_pos = vim.api.nvim_win_get_cursor(current_win)
  local row, col = cursor_pos[1], cursor_pos[2]
  
  -- Calculate window position (above cursor)
  local win_height = 1  -- Single line input
  local win_width = math.floor(vim.o.columns * 0.8)
  local win_row = row - 1  -- Position above current line
  local win_col = math.floor((vim.o.columns - win_width) / 2)  -- Centered
  
  -- Create a scratch buffer for input
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Initial prompt text with brain emoji
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"🧠 > "})
  
  -- Set cursor at end of prompt
  local prompt_len = #"🧠 > "
  
  -- Create floating window
  local opts = {
    relative = 'win',
    win = current_win,
    row = win_row,
    col = win_col,
    width = win_width,
    height = win_height,
    style = 'minimal',
    border = 'rounded'
  }
  
  local win = vim.api.nvim_open_win(buf, true, opts)
  
  -- Set cursor position after the prompt
  vim.api.nvim_win_set_cursor(win, {1, prompt_len})
  
  -- Enter insert mode
  vim.cmd('startinsert!')
  
  return {
    buf = buf,
    win = win,
    prompt_len = prompt_len
  }
end

-- Add this to your M table
M.create_input_window = create_input_window

-- Function to capture input and process it
local function prompt_input_and_process(model_function)
  local win_info = create_input_window()
  
  -- Set up an autocommand to handle when the user presses Enter
  local input_group = vim.api.nvim_create_augroup("LLMInputGroup", { clear = true })
  vim.api.nvim_create_autocmd("BufLeave", {
    group = input_group,
    buffer = win_info.buf,
    callback = function()
      -- Get input text, removing the prompt
      local lines = vim.api.nvim_buf_get_lines(win_info.buf, 0, 1, false)
      local input_text = ""
      if #lines > 0 then
        -- Extract only the user input by removing the prompt
        input_text = string.sub(lines[1], win_info.prompt_len + 1)
      end
      
      -- Close the floating window
      vim.api.nvim_win_close(win_info.win, true)
      
      -- If we have input, process it
      if input_text and input_text ~= "" then
        -- Return to normal mode in the original window
        vim.cmd("stopinsert")
        
        -- Call the provided model function with the input
        model_function(input_text)
      end
    end,
    once = true,
  })
  
  -- Set up key mapping for <ESC> to cancel
  vim.api.nvim_buf_set_keymap(win_info.buf, "i", "<ESC>", "", {
    callback = function()
      vim.api.nvim_win_close(win_info.win, true)
      vim.cmd("stopinsert")
    end,
    noremap = true,
    silent = true
  })
  
  -- Set up key mapping for <CR> to submit
  vim.api.nvim_buf_set_keymap(win_info.buf, "i", "<CR>", "", {
    callback = function()
      vim.api.nvim_win_close(win_info.win, true)
      -- The BufLeave autocmd will handle processing
    end,
    noremap = true,
    silent = true
  })
end

-- Add these functions to M
M.prompt_input_and_process = prompt_input_and_process

-- Create wrapper functions for each API
local function grok_replace_from_prompt(prompt_text)
  M.invoke_llm_and_stream_into_editor({
    url = 'https://api.x.ai/v1/chat/completions',
    model = 'grok-3-latest',
    api_key_name = 'GROK_API_KEY',
    system_prompt = system_prompt,
    replace = false,
    prompt = prompt_text,
  }, M.make_openai_spec_curl_args, M.handle_openai_spec_data)
end

local function grok_help_from_prompt(prompt_text)
  M.invoke_llm_and_stream_into_editor({
    url = 'https://api.x.ai/v1/chat/completions',
    model = 'grok-3-latest',
    api_key_name = 'GROK_API_KEY',
    system_prompt = helpful_prompt,
    replace = false,
    prompt = prompt_text,
  }, M.make_openai_spec_curl_args, M.handle_openai_spec_data)
end

local function anthropic_help_from_prompt(prompt_text)
  M.invoke_llm_and_stream_into_editor({
    url = 'https://api.anthropic.com/v1/messages',
    model = 'claude-3-7-sonnet-20250219',
    api_key_name = 'ANTHROPIC_API_KEY',
    system_prompt = helpful_prompt,
    replace = false,
    prompt = prompt_text,
  }, M.make_anthropic_spec_curl_args, M.handle_anthropic_spec_data)
end

local function anthropic_replace_from_prompt(prompt_text)
  M.invoke_llm_and_stream_into_editor({
    url = 'https://api.anthropic.com/v1/messages',
    model = 'claude-3-7-sonnet-20250219',
    api_key_name = 'ANTHROPIC_API_KEY',
    system_prompt = system_prompt,
    replace = false,
    prompt = prompt_text,
  }, M.make_anthropic_spec_curl_args, M.handle_anthropic_spec_data)
end

-- Add the prompt-based functions to M
M.grok_replace_from_prompt = grok_replace_from_prompt
M.grok_help_from_prompt = grok_help_from_prompt
M.anthropic_help_from_prompt = anthropic_help_from_prompt
M.anthropic_replace_from_prompt = anthropic_replace_from_prompt

-- Create helpers to invoke the prompt window with a specific model
M.prompt_grok_replace = function()
  prompt_input_and_process(grok_replace_from_prompt)
end

M.prompt_grok_help = function()
  prompt_input_and_process(grok_help_from_prompt)
end

M.prompt_anthropic_help = function()
  prompt_input_and_process(anthropic_help_from_prompt)
end

M.prompt_anthropic_replace = function()
  prompt_input_and_process(anthropic_replace_from_prompt)
end

return M