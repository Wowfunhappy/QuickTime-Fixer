# QuickTime-Fixer
Mountain Lion QuickTime supports third party codecs. This means you can install Perian and play all sorts of videos! I wanted to use this version of QuickTime on Mavericks!

I got it 95% working just by relinking frameworks via install_name_tool. For the last 5%, I had to inject the code in this repo. It's heavily commented, so feel free to take a look: https://github.com/Wowfunhappy/QuickTime-Fixer/blob/master/QuickTimeFixer/main.m

Or, if you're running **Mac OS X 10.9 Mavericks**, just download the app: https://github.com/Wowfunhappy/QuickTime-Fixer/releases

Note, while this is designed to replace the system QuickTime, please do make sure to keep a backup of the original!
