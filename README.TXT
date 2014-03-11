SpaSe PCRadio Control v2.2
==========================

<turn your word wrap on>

1. What does it do?

   This program has complete control over the radio card known as PC SpaSe Radio 003 (an ancient ISA card). 
It was written specifically to control this card, and shouldn't work with no other radio cards.


2. Why did you do this?

   Well, I had two of these cards waaaaay back in 1998(or was it 1997? who knows), and after using the software that came with it for a few months, decided to write my own. The original software was VERY cute, in VGA, using the mouse, sound card, with a great graphical interface... but incredibly slow to load on my puny machines at the time. Plus, I was into OS/2 at the time, and this program was a dog to run in a OS/2 Window (yes it did run fine after some tweaking, but I didn't like it switching video modes). I needed something SIMPLE, that I could control with the keyboard, took no resources and could pass parameters at the command-line so I could automate it (e.g. use it as an alarm-clock with a Cron program).
   
   I wrote this in about a month after I found the card's SDK for Win**** lost in SpaSe's site at the time. This program was written in Virtual Pascal 2.1 (see http://www.vpascal.com -- check it out!) because I needed it to run on OS/2, DOS and Win32. Only the OS/2 and DOS versions are 100% complete. The Win32 version was made (you can see the tons of $ifdefs in the code), and is fully functional, but I never got to research a way to write the binary ANSI screen on a Win32 console, as apparently it has almost no text or graphical functions available. A Linux version was planned, but the Linux support in VP was still very lacking at the time. 
   
   This program served me quite well for a few years. You can find the last binary I compiled for DOS, Win32 and OS/2 at:
    
    	http://hobbes.nmsu.edu/pub/os2/apps/mmedia/misc/spasepcradio-223.zip

   Hobbes is the great and venerable OS/2 software archive that has resisted through all these years of Win* versions and numerous Linux distributions. Long live OS/2, you were the best, always ahead of your time!
   
   
3. Why are you releasing this?

   That's the strange part. For quite some time I didn't hear from anyone about this. Then a couple of years later, somebody emailed me about it. I thought that was it. Then another. And another. And another...
   Then came an email from Fritz, a guy from Germany that collects radio cards. After getting his SpaSe PCRadio up and running, I thought, "What the hell, I'll just release this as GPL" but never got to do it. Now, I got yet another email from a hobbyist that wants to make his own program. Well, there you have it, Leo :)
   
   (Fritz, if you're reading this, how's your collection? Too bad I never got that USB radio you sent me :( )
   
4. Why GPL?    

   Well, GPL was the logical thing to do. Anyway, there are still some restrictions. I can only release as GPL the part that I wrote completely, that is, the main program. As for the other source files:
   
   - TIMETASK.PAS: this came from an old SWAG article. SWAG is(was?) a very fine and free Pascal/Delphi code archive. It's reYou can (still) find it at: http://www.gdsoft.com/swag/swag.html
   
   - SCANCODE.PAS: this probably came from SWAG too. Or from somewhere in the web. Or even from a BBS at the time. Who knows... The credits are in the file header.
   
   - PCR_SUPW.PAS: this was part of the original Windows SDK from SpaSe. As this is quite ANCIENT (1990!), I don't know what is the status of this. I did make quite a lot of changes in the code in order to support multiple operating systems, and solved a few timing problems the original had.
   
   If you are the author of any of these sources and wish to have these removed from the archive, just tell me so.
   
   For those that are either too young or didn't understand what RADIOC.PAS is, it's a Pascal array created off an ANSI screen (RADIOC.ANS) by a program named TheDraw. Yes, children, ANSI. Wait. Let me grab my pipe. No, wait, I don't smoke. Well, in a time before there was the Internet, dinosaurs roamed the earth (actually stayed inside the house for days) dialing up BBSes at incredible speeds like 1200 up to 14400 bauds. Some fortunate ones even had 28800 or 33600 baud modems! They relied on this ancient art known as ANSI, to make their menus, logos and texts that were sent through the phone lines. TheDraw was the best editor ever made for this, and was able to export the screens to a Pascal array which I used to draw the interface for this program.
   
   
5. Contact

   You can contact me at slaughter@malaconet.org , but can't guarantee any support whatsoever. I still have the cards, but no ISA slot to put them on, and haven't used them for years. All that I can guarantee is that this program was working perfectly with me, and apparently is still working perfectly for quite a few people.
   
   -- Erico Mendonca
   Jul 30th 2004
   