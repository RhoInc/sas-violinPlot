/*----------------------- Copyright 2016, Rho, Inc.  All rights reserved. ------------------------\

  Study:        sas-violinPlot

    Program:    runViolinPlot.sas

      Purpose:  Generate example violin plots

      Input:    SASHELP.CARS
                <repository directory>\violinPlot.sas

      Output:   <repository directory>\boxAndWhiskerPlot.(pdf png)
                <repository directory>\violinPlot.(pdf png)

      Macros:   %violinPlot

  /-----------------------------------------------------------------------------------------------\
    Program History:
  \-----------------------------------------------------------------------------------------------/

      Date        Programmer          Description
      ----------  ------------------  ------------------------------------------------------------
      2016-02-02  Spencer Childress   Create

\------------------------------------------------------------------------------------------------*/

    %sysexec <repository drive>;
    %sysexec cd "<repository diretory>";

    ods listing
        gpath = '.';

    options threads
        compress = char;

/*------------------------------------------------------------------------------------------------\
  Data manipulation
\------------------------------------------------------------------------------------------------*/

    proc sort
        data = sashelp.cars (where = (cylinders in (4 6 8)))
        out = cars;
        by Cylinders Origin Horsepower;
    run;

/*------------------------------------------------------------------------------------------------\
  Figures
\------------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------\
      Box-and-Whisker plot
    \--------------------------------------------------------------------------------------------*/

        proc sql noprint;
            select
                ceil(max(Horsepower))
              into :max trimmed
                from cars;
        quit;

        title;
        footnote;

        options
            orientation = landscape;

        ods results off;

            ods graphics on /
                reset = all
                border = no
                width = 10in
                height = 7.5in
                imagename = 'boxAndWhiskerPlot'
                imagefmt = pdf
                outputfmt = pdf;

            ods pdf
                file = 'boxAndWhiskerPlot.pdf';
                title1 j = c 'Horsepower';
                title2 j = c 'Paneled by Cylinders';
                %macro boxAndWhisker;
                    proc sgpanel
                        data = cars;
                        panelby Cylinders / novarname
                            rows = 1;
                        vbox Horsepower /
                            group = Origin;
                        rowaxis values = (0 to &max);
                    run;
                %mend  boxAndWhisker;
                %boxAndWhisker
            ods pdf close;

            ods graphics on /
                reset = all
                border = no
                width = 10in
                height = 7.5in
                imagename = 'boxAndWhiskerPlot'
                imagefmt = png
                outputfmt = png;

                %boxAndWhisker

        ods results;

    /*--------------------------------------------------------------------------------------------\
      Violin plot
    \--------------------------------------------------------------------------------------------*/

        %include 'violinPlot.sas';
        %violinPlot
            (data              = cars
            ,outcomeVar        = Horsepower
            ,groupVar          = Cylinders
            ,panelVar          = Origin
            ,byVar             = 
            ,widthMultiplier   = .1
            ,jitterYN          = Yes
            ,quartileYN        = Yes
            ,quartileSymbolsYN = No
            ,meanYN            = Yes
            ,trendLineYN       = Yes
            ,trendStatistic    = Median
            );

/*------------------------------------------------------------------------------------------------\
  Cleanup
\------------------------------------------------------------------------------------------------*/

    %sysexec del SGPanel.*;
