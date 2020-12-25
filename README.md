# QuickTime-Fixer
Mountain Lion QuickTime supports third party codecs. This means you can install Perian and play all sorts of videos! I wanted to use this version of QuickTime on Mavericks!

Unfortunately, when I get my head set on accomplishing something, it takes me way too long to give up. In this case, it mostly works... except for some some cosmetic issues. They're kind of minor, but bothersome if you're a stickler for details.

Getting QuickTime to work mostly involved relinking the right frameworks. The [code I inject](https://github.com/Wowfunhappy/QuickTime-Fixer/blob/master/QuickTimeFixer/NSObject%2BSwizzling.m) attempts to fix visual issues when opening audio files (or making a screen recording). I'm somewhat somewhat embarassed by how long it took to get to these ~50 lines—I have no idea what's actually causing the glitches, and so resorted to poking at random functions. I successfully managed to make the window background appear.

Misc:
- Audio files:
  - Window corners are too round (8px instead of 4px).
  - Windows don't have a shadow.
  - When de-minimizing a window, the contents of the window won't appear until the genie animation has finished playing.
- Other files:
  - Videos initially don't have a window shadow. It will appear if you click on another window, then back on the video.
  - The menu bar won't change to QuickTime when you first open the program. You need to switch to another app, then back to QuickTime.
 
