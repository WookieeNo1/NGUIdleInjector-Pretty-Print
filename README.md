# NGUIdleInjector-Pretty-Print

This is a simple powershell script (my first, so please don't bite) to pretty print the output from 
NGU Injector Continued.
(https://github.com/thure-CodeMeister/NGUInjector-Continued)

It requires PS 7, and will terminate if any other version is detected.

Run using:

    & <Directory>NGUInjectorPrettyPrint.ps1
    
    which displays a simple menu with options to either display the full file, or run continuously displaying
    the last 30 lines added. There is also a very rudimentary help. This menu will default with the highlighted 
    options after 10 seconds of inactivity.

It can accept 3 parameters (either by the named parameters below, or using the raw values in the position indicated):

    -LogFile <Filename>
        - the name of the log to Pretty Print. 
            (Inject.log, PitSpin.Log, or Loot.Log are the only valid options)

    -DisplayMode <DisplayMode>
        - full (Processes the entire file and ends)
        - tail (runs continuously displaying the last 30 lines added. Exit by pressing Ctrl-C)

    -LineFilter <String>
        - Only lines containing the string will be included. Be aware that this may result in some lines being 
          incorrectly colour coded.
        
If either of the LogFile or Displayname parameters is invalid, it will display the menu.

TODO:

    Line lengths sometimes wrap around in the raw PS console 
    (As a quick fix, I recommend Windows Terminal, which can be downloaded at 
    https://www.microsoft.com/en-gb/p/windows-terminal/9n0dx20hk701#activetab=pivot:overviewtab )

    There are some log entries it has yet to handle, due to not having any examples to test.

Changelog

    Cube Progress now highlights numerical values, as does Turning in Quest Items
    There are some places where the detection/highlighting of numbers includes any following text. This has been fixed
    
    PitSpin: Removed Blank Line in 'You Gained' entries and Indented associated lines

    PitSpin: Added Colours.csv to allow User-defined colours for Money Pit Rewards entries 
                - remove # to activate and set colour value as required

    Colours.csv: added clrHyperbole - set to 0 to make them disappear

    Colours.csv: Removed, now created as necessary with all legal User-defined colours 

    Menu system overhauled - it now displays valid command line parameters, and allows the selection of Display mode and
    Logfile

    Colours.CSV is now monitored while running, and valid changes will be applied dynamically. Any errors within the file will 
    result in the changed version being written to Colours.OLD (overwriting any existing copy), and the default values written 
    out again.

(Yes, I'm British)
