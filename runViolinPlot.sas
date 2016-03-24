                           %include 'S:\BASESTAT\RhoUtil\gridReset.sas';
                                %gridReset(H:\SAS\sas-violinPlot);
;                                                                                                 ;
/*----------------------- Copyright 2016, Rho, Inc.  All rights reserved. ------------------------\

  Study:        sas-violinPlot

    Program:    runViolinPlot.sas

      Purpose:  Generate example violin plots

      Input:    SASHELP.CARS
                <repository directory>\violinPlot.sas

        Macros: %violinPlot

      Output:   <repository directory>\violinPlot.pdf

  /-----------------------------------------------------------------------------------------------\
    Program History:
  \-----------------------------------------------------------------------------------------------/

      Date        Programmer          Description
      ----------  ------------------  ------------------------------------------------------------
      2016-02-02  Spencer Childress   Create

\------------------------------------------------------------------------------------------------*/

    /*%sysexec <repository drive>;
    %sysexec cd "<repository diretory>";*/
    %sysexec H:;
    %sysexec cd SAS\sas-violinPlot;

    ods listing
        gpath = '.';

    options
        compress = char threads
        linesize = 104
        pagesize =  79;

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
                width = 10.5in
                height = 8in
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
                width = 10.5in
                height = 8in
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
            (data            = cars
            ,outcomeVar      = Horsepower
            ,groupVar        = Origin
            ,panelVar        = Cylinders
            ,byVar           = 
            ,widthMultiplier = .1
            ,trendLineYN     = Yes
            );

/*------------------------------------------------------------------------------------------------\
  Cleanup
\------------------------------------------------------------------------------------------------*/

    %sysexec del SGPanel.*;