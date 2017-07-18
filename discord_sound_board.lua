local discordia = require("discordia")
local fs = require("fs")

--user defined constants below.
local opus_path = "/usr/lib64/libopus.so.0.6.1"
local sodium_path = "/usr/lib64/libsodium.so.18.2.0"
local bot_token = "your-token-here"
local sounds_location = "/path/to/sounds/"
--end user constants

local client = discordia.Client()

client.voice:loadOpus(opus_path)
client.voice:loadSodium(sodium_path)

function waitSeconds(seconds)
  local start = os.time()
  repeat until os.time() > start + seconds
end

local sounds_list = {}

function sounds_list:refresh()
    local files = fs.readdirSync(sounds_location)
    for index, file in pairs(files) do
        self["!sb_" .. string.sub(file, 1, -5)] = sounds_location .. file
    end
end

function sounds_list:randomSound()
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

local sounds_queue = {}

function sounds_queue:enqueue(val)
    table.insert(self, val)
end

function sounds_queue:dequeue()
    return table.remove(self, 1)
end

function sounds_queue:isEmpty()
    if self[1] then
        return false
    else
        return true
    end
end

function sounds_queue:clear()
    while not self:isEmpty() do
        self:dequeue()
    end
end


client:on("ready", function()
    print("Logged in as:", client.user.username)
end)

local voice_channel = nil
local voice_connection = nil
local now_playing = nil

local function playQueue()
    if voice_channel and
       voice_connection and not
       voice_connection.isPlaying then
        while not sounds_queue:isEmpty() do
            local sound = sounds_queue:dequeue()
            local sound_file = sounds_list[sound]
            print("playing: ", sound_file)
            now_playing = sound
            client:setGameName(sound)
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

client:on('messageCreate', function(message)
    if sounds_list[message.content] then
        message:delete()
        print("queuing:", sounds_list[message.content])
        sounds_queue:enqueue(message.content)
        
        if not voice_connection then
            voice_channel = message.member.voiceChannel
            voice_connection = voice_channel:join()
        end
        
        pcall(playQueue)
    elseif message.content == "!sb_list" then
        message:delete()
        local sounds = "**Available Sounds**\n```\n"
        for key, value in pairs(sounds_list) do
            sounds = sounds .. key .. "\n" 
        end
        sounds = sounds .. "```"
        message.channel:sendMessage(sounds)
    elseif message.content == "!sb_refresh" then
        message:delete()
        sounds_list:refresh()
    elseif message.content == "!sb_queue" then
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
    elseif message.content == "!sb_skip" then
        message:delete()
        if voice_connection then
            voice_connection:stopStream()
        end
    elseif message.content == "!sb_stfu" then
        message:delete()
        if voice_connection then
            voice_connection :stopStream()
        end
        sounds_queue:clear()
    end
end)

sounds_list:refresh()
client:run(bot_token)

