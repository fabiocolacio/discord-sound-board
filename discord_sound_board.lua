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

client:on("ready", function()
    print("Logged in as:", client.user.username)
end)

local voice_channel = nil
local voice_connection = nil

client:on('messageCreate', function(message)
    if sounds_list[message.content] then
        print("queuing:", sounds_list[message.content])
        sounds_queue:enqueue(sounds_list[message.content])
        
        if not voice_connection then
            voice_channel = message.member.voiceChannel
            voice_connection = voice_channel:join()
        end
        
        if voice_connection and not voice_connection.isPlaying then
            while not sounds_queue:isEmpty() do
                local sound = sounds_queue:dequeue()
                print("playing: ", sound)
                voice_connection:playFile(sound)
                print("done playing:", sound)
            end
            
            voice_channel:leave()
            voice_channel = nil
            voice_connection = nil
        end
    end
end)

sounds_list:refresh()
client:run(bot_token)

