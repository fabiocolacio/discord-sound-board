local discordia = require("discordia")
local client = discordia.Client()

--user defined constants below.
local opus_path = "/usr/lib64/libopus.so.0.6.1"
local sodium_path = "/usr/lib64/libsodium.so.18.2.0"
local bot_token = "your-token-here"
local sounds_location = "/path/to/sounds/"
--end user constants

client.voice:loadOpus(opus_path)
client.voice:loadSodium(sodium_path)

local voice_connection = nil
local voice_channel = nil

local commands_list = {}

local sounds_list = {}

local function playSound(sound)
    if voice_connection then
        coroutine.wrap(function()
            print("playing file: ", sounds_list[sound])
            voice_connection:playFile(sounds_list[sound])
            voice_channel:leave()
        end)()
    end
end

local function summon(message)
    local connection = nil
    for channel in client.voiceChannels do
	        for member in channel.members do
	            if member.username == message.author.username then
	                connection = channel:join()
	                voice_channel = channel
	                goto channel_found
	            end
	        end
	    end
	    ::channel_found::
	    
	    if not connection then
	        voice_channel = nil
	        message.channel:sendMessage(
	            "**Failed to join the voice channel!**\n" ..
	            "Make sure you are in a voice channel when " .. 
	            "adding a sound to the queue.")
	    end
	    
	    return connection
end

function sounds_list:rand()
    math.randomseed(os.time())
    local stop = math.random(self.len)
    local index = 0
    for key, value in pairs(self) do
        if (stop == index) then
            return value
        end
        index = index + 1
    end
    return nil
end

--COMMAND ACTIONS

local function loadSoundsList()
    local len = 0
    local file = assert(io.popen("/bin/ls " .. sounds_location, "r"))
    io.input(file)
    for line in io.lines() do
        sounds_list["!sb_" .. string.sub(line, 0, -5)] = sounds_location .. line
        len = len + 1
    end
    io.close(file)
    sounds_list.len = len
end

local function stfu()
    if voice_connection then
        voice_connection:stopStream()
    end
end

local function help(message)
    local h = "**SoundBoard Help**\n"
    for key, value in pairs(commands_list) do
        h = h ..
            "*" .. key  .. "*\n" ..
            "```" .. value.description .. "```\n"
    end
    message.channel:sendMessage(h)
end

local function list(message)
    local sounds = ""
    for key, value in pairs(sounds_list) do
        sounds = sounds .. key .. "\n"
    end
    message.channel:sendMessage("**Sounds:**\n```" .. sounds .. "```")
end

local function rand(message)
    voice_connection = summon(message)
    if voice_connection then
        local file = sounds_list:rand()
        if file then
            coroutine.wrap(function()
                print("playing file:", file)
                voice_connection:playFile(file)
                voice_channel:leave()
            end)()
        end
    end
end

--COMMAND DECLARATIONS

commands_list["!sb_refresh"] = {
    ["description"] = "Refresh the internal list of available soundclips",
    ["do"] = loadSoundsList
}

commands_list["!sb_stfu"] = {
    ["description"] = "Stop the current sound clip if one is playing",
    ["do"] = stfu
}

commands_list["!sb_help"] = {
    ["description"] = "Show the help dialog",
    ["do"] = help
}

commands_list["!sb_list"] = {
    ["description"] = "Show all available sound clips",
    ["do"] = list
}

commands_list["!sb_rand"] = {
    ["description"] = "Play a random sound clip",
    ["do"] = rand
}

client:on('ready', function()
    print('Logged in as '.. client.user.username)
end)

client:on('messageCreate', function(message)
    if sounds_list[message.content] then
        voice_connection = summon(message)
        if voice_connection then
            coroutine.wrap(function()
                print("playing file: ", sounds_list[message.content])
                voice_connection:playFile(sounds_list[message.content])
                voice_channel:leave()
            end)()
        end
    elseif commands_list[message.content] then
        commands_list[message.content]["do"](message)
    end
end)

loadSoundsList()
--add your token below
client:run(bot_token)

