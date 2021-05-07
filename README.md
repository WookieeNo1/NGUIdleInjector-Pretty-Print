# NGUIdleInjector-Pretty-Print

This is a simple powershell script (my first, so please don't bite) to pretty print the output from NGU Injector Continued.
(https://github.com/thure-CodeMeister/NGUInjector-Continued)

It requires PS 7, and will terminate iF any other version is detected.

Run using 

    & <Directory>NGUInjectorPrettyPrint.ps1
    
    which displays a simple menu with options to either display the full file, or run continuously displaying the 
    last 2 lines added. There is also a very rudimentary help. This menu will default to the continuous option after 
    5 seconds.

It can accept 2 parameters (either by the named parameters below, or using the raw values):

    -LogFile <Filename>
        - the name of the log to Pretty Print. 
            (Inject.log, PitSpin.Log, or Loot.Log are the only valid options)

    -DisplayMode <DisplayMode>
        - full (Processes the entire file and ends)
        - tail (runs continuously displaying the last 2 lines added. Exit by pressing Ctrl-C)

If either parameter is invalid, it will display the menu.

TODO:

    Line lengths sometimes wrap around in the raw PS console 
    (As a quick fix, I recommend Windows Terminal, which can be downloaded at 
    https://www.microsoft.com/en-gb/p/windows-terminal/9n0dx20hk701#activetab=pivot:overviewtab )

    There are some places where the detection/highlighting of numbers includes any following text. 

    The menu ONLY accesses Inject.log, this will be fixed to allow file selection
    
    There are some log entries it has yet to handle, due to not having any examples to test.
    