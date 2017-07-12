local discordia = require("discordia")
local client = discordia.Client()

--replace library_path with the path to your libopus and libsodium so's or dll's
local library_path = "/usr/lib64/"
--replace versioning and naming as necessary
client.voice:loadOpus(library_path .. 'libopus.so.0.6.1')
client.voice:loadSodium(library_path .. 'libsodium.so.18.2.0')

local voice_connection = nil
local voice_channel = nil

local commands_list = {}

local sounds_list = {}
--replace sounds_location with the path to your sounds folder
local sounds_location = "/path/to/sounds/"

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
	            "Make sure you are in a voice channel when typing " ..
	            "``!sb_summon``.")
	    end
	    
	    return connection
end

--COMMAND ACTIONS

local function loadSoundsList()
    local file = assert(io.popen("/bin/ls " .. sounds_location, "r"))
    io.input(file)
    for line in io.lines() do
        sounds_list["!sb_" .. string.sub(line, 0, -5)] = sounds_location .. line
    end
    io.close(file)
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
    local seed = 123
    if voice_connection then
        for key, value in pairs(sounds_list) do
            seed = seed + os.time() / 2
            math.randomseed(seed)
            if math.random(100) > 50 then
                coroutine.wrap(function()
                    print("playing file: ", value)
                    voice_connection:playFile(value)
                    voice_channel:leave()
                end)()
                break
            end
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
client:run('your_token_here')

