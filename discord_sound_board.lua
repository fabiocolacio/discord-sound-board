local discordia = require("discordia")
local fs = require("fs")

local Queue = require("Queue")
local Command = require("Command")

local config = require("config")

local client = discordia.Client()

client.voice:loadOpus(config.opus_path)
client.voice:loadSodium(config.sodium_path)

local sounds_list = { len = 0 }

function sounds_list:refresh()
    local items = fs.scandirSync(config.sounds_location)
    
    local function generate_command(filename, category_name)
        assert(type(filename) == "string",
               "Parameter: 'filename' should be a string")
        local dot = filename:find("%.")
        if dot then dot = dot - 1 end
        local command = config.command_prefix .. filename:sub(1, dot)
        local path
        if category_name == "Uncategorized" then
            path = config.sounds_location .. filename
        else
            path = config.sounds_location .. category_name .. "/" .. filename
        end
        self[category_name][command] = path
        self.len = self.len + 1
    end
    
    for item, kind in items do
        if kind == "file" then
            if not self["Uncategorized"] then
                self["Uncategorized"] = {}
            end
            generate_command(item, "Uncategorized")
        elseif kind == "directory" then
            self[item] = {}
            local files = fs.scandirSync(config.sounds_location .. item)
            for file, kind in files do
                if kind == "file" then
                    generate_command(file, item)
                end
            end
        end
    end
end

do
    local seed = 7
    function sounds_list:randomSound()
        seed = seed + 3 * os.time()
        math.randomseed(seed)
        local stop = math.random(self.len)
        local index = 0
        for category, table in pairs(self) do
            if type(table) == "table" then
                for key, value in pairs(table) do
                    if (stop == index) then
                        return category, key
                    end
                    index = index + 1
                end
            end
        end
    end
end

local sounds_queue = Queue()

local voice_channel = nil
local voice_connection = nil
local now_playing = nil

local commands_table = {}

local function playQueue()
    if voice_channel and
       voice_connection and not
       voice_connection.isPlaying then
        while not sounds_queue:isEmpty() do
            local sound = sounds_queue:dequeue()
            local category = sound[1]
            local command = sound[2]
            local sound_file = sounds_list[category][command]
            print("playing: ", sound_file)
            now_playing = command
            client:setGameName(command)
            voice_connection:playFile(sound_file)
            print("done playing:", sound_file)
        end
        
        voice_channel:leave()
        voice_channel = nil
        voice_connection = nil
        now_playing = nil
        client:setGameName(nil)
    end
end

do -- bot commands and descriptions defined here
    local function random(message)
        message:delete()
        
        if not voice_connection then
            voice_channel = message.member.voiceChannel
            voice_connection = voice_channel:join()
        end
        
        local category, sound = sounds_list:randomSound()
        if sound then
            print("queuing:", sound)
            sounds_queue:enqueue({category, sound})
            pcall(playQueue)
        end
    end
    commands_table[config.command_prefix .. "rand"] = 
        Command(random, "Play a random sound.")

    local function search(message)
        local s, e = message.content:find(config.command_prefix .. "search")
        if s == 1 then
            local query = message.content:sub(e + 2)
            local results = "**Searching For:** *" .. query ..  "*\n```\n"
            for category, table in pairs(sounds_list) do
                if type(table) == "table" then
                    for command in pairs(table) do
                        if command:find(query) then
                            results = results .. command .. "\n"
                        end
                    end
                end
            end
            results = results .. "```"
            message.channel:sendMessage(results)
        end
    end
    commands_table[config.command_prefix .. "search"] =
        Command(search, "Search for a sound containing a keyword")

    local function help(message)
        message:delete()
        local help_message = "**Help**\n"
        for key, command in pairs(commands_table) do
            help_message = help_message ..
                           string.format("**%s:** *%s*\n",
                                         key,
                                         command.description)
        end
        message.channel:sendMessage(help_message)
    end
    commands_table[config.command_prefix .. "help"] = 
        Command(help, "Show the help dialog.")

    local function list(message)
        message:delete()
        local sounds = "**Available Sounds**\n\n"
        for category, table in pairs(sounds_list) do
            if type(table) == "table" then
                sounds = sounds .. "**" .. category .. "**\n```\n"
                for key, value in pairs(table) do
                    sounds = sounds .. key .. "\n"
                end
                sounds = sounds .. "```\n\n"
            end
        end
        message.channel:sendMessage(sounds)
    end
    commands_table[config.command_prefix .. "list"] =
        Command(list, "List all available sounds.")

    local function refresh(message)
        message:delete()
        sounds_list:refresh()
    end
    commands_table[config.command_prefix .. "refresh"] =
        Command(refresh, "Refresh the list of available sounds.")

    local function queue(message)
        message:delete()
        local queue = "**Queued Sounds**\n```\n" ..
                      "Currently Playing:\n" ..
                      (now_playing or "none") .. "\n\n" ..
                      "Coming Up:\n"
        if sounds_queue:isEmpty() then
            queue = queue .. "none"
        else
            for index, value in ipairs(sounds_queue) do
                queue = queue .. string.format("%d)\t%s\n", index, value)
            end
        end
        queue = queue .. "```"
        message.channel:sendMessage(queue)
    end
    commands_table[config.command_prefix .. "queue"] = 
        Command(queue, "Show all the sounds in the queue.")

    local function skip(message)
        message:delete()
        if voice_connection then
            voice_connection:stopStream()
        end
    end
    commands_table[config.command_prefix .. "skip"] = 
        Command(skip, "Skips to the next sound in the queue.")

    local function stfu(message)
        message:delete()
        if voice_connection then
            voice_connection :stopStream()
        end
        sounds_queue:clear()
    end
    commands_table[config.command_prefix .. "stfu"] =
        Command(stfu, "Stops currently playing sound, and clears the queue.")     
end -- end of command descriptions.

client:on('messageCreate', function(message)
    if sounds_list then
        for category, table in pairs(sounds_list) do
            if type(table) == "table" then
                if table[message.content] then
                    message:delete()
                    print("queuing:", table[message.content])
                    sounds_queue:enqueue({category, message.content})
                    if not voice_connection then
                        voice_channel = message.member.voiceChannel
                        voice_connection = voice_channel:join()
                    end
                    pcall(playQueue)
                end
            end
        end
    end
    
    if commands_table[message.content] then
        commands_table[message.content].action(message)
    else
        commands_table[config.command_prefix .. "search"].action(message) 
    end
end)

client:on("ready", function()
    print("Logged in as:", client.user.username)
end)

sounds_list:refresh()
client:run(config.bot_token)

