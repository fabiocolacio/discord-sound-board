# SoundBoard

SoundBoard is a bot for discord which is capable of playing sounds in the
voice channels of a discord server.

Once SoundBoard is setup, you simply need to create a folder in your computer
filled with sound files, and users will be able to command the bot to
play them in the voice channels

## Run it yourself

### Dependencies

**Note:** The current build of this uses the ``ls`` command to list
the contents of a directory, and this might not work in Windows. If anybody
finds a better way of doing this, feel free to make a pull request.

You will need to install the Luvit Lua distribution at
[luvit.io](https://luvit.io/).

Next, you will need to install the
[Discordia](https://github.com/SinisterRectus/Discordia) library. Discordia
can be easily installed with the ``lit`` command includeded with Luvit.
Simply open a terminal and type ``lit install SinisterRectus/discordia``

Finally, you will need ``libopus``, ``libsodium``, and ``ffmpeg`` installed.
If you are using linux, these are in the package managers of most distros.

### Creating and running the bot

First, you must register your bot with discord
[here](https://discordapp.com/developers/applications/me/create).
Make sure to set the app as a bot user.

Next, add the bot to a server with this link:
```
https://discordapp.com/api/oauth2/authorize?client_id=your_id_here&scope=bot&permissions=0
```
You will need to replace ``your_id_here`` in the link, with your bot's client_id.

Next look through the code in ``discord_sound_board.lua``, and replace the
following strings with your own info:
```
opus_path       => the path to the opus library
sodium_path     => the path to the sodium library
bot_token       => your bot's discord token
sounds_location => the path to the folder containing all the sounds for the bot
```

You can finally run the bot by running the lua file.

