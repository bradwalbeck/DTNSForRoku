@ECHO OFF

SET hr=%time:~0,2%
IF %hr% lss 10 SET hr=0%hr:~1,1%

REM This sets the date like this:  mm-dd-yr-hrminsecs1/100secs
Set TODAY=%date:~4,2%-%date:~7,2%-%date:~10,4%-%hr%%time:~3,2%%time:~6,2%%time:~9,2%

ECHO.
ECHO Zipping all files in :.\DTNSForRoku\DTNSForRoku\ and moving archive to .\DTNSForRoku\packages\
ECHO.
compact /c /s:"D:\Libraries\Documents\GitHub\DTNSForRoku\DTNSForRoku\DTNSForRoku\channel" "D:\Libraries\Documents\GitHub\DTNSForRoku\DTNSForRoku\DTNSForRoku\builds\DTNSForRoku%TODAY%.zip"
ECHO.

ECHO Done.

PAUSE.