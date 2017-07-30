local config = {
    -- Paths to opus and sodium dll's, dylib's, or so's
    opus_path = "/path/to/opus",
    sodium_path = "/path/to/sodium",
    
    -- Get this from your developer portal
    bot_token = "bot-token-here",
    
    -- You need the final '/' in this path
    sounds_location = "/path/to/sounds/",
    
    -- The prefix for all the commands.
    -- Change this to avoid conflicts with other bot commands.
    -- e.g. if prefix is '!sb_', commands will be '!sb_help', '!sb_list', etc.
    command_prefix = "!",
}

return config
