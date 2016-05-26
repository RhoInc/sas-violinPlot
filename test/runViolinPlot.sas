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


   *Set the working drive and directory below before running program.;
    %sysexec <repository drive>;
    %sysexec cd "<repository directory>";
    %*sysexec H:;
    %*sysexec cd "H:\SAS\sas-violinPlot";

    ods listing
        gpath = 'output';

    options threads
        compress = char;

    %include 'src\violinPlot.sas';

/*------------------------------------------------------------------------------------------------\
  Data manipulation
\------------------------------------------------------------------------------------------------*/

    proc sort
        data = sashelp.cars (where = (cylinders in (4 6 8)))
        out = cars;
        by Cylinders Origin Horsepower;
    run;

    data test;
        do i = 1 to 100;
                Outcome = ranuni(-1)*ifn(i le 5, 3, 1);
            output;
        end;
    run;

/*------------------------------------------------------------------------------------------------\
  Figures
\------------------------------------------------------------------------------------------------*/

    /*--------------------------------------------------------------------------------------------\
      Box-and-Whisker plot
    \--------------------------------------------------------------------------------------------*/

        ods graphics /
            reset = all
            border = no
            width = 10.5in
            height = 8in
            imagename = "boxAndWhiskerPlotExample"
            imagefmt = png
            outputfmt = png
            antialiasmax = 10000;

        proc sgplot
            data = test;
            vbox outcome;
        run;

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
                file = 'output\boxAndWhiskerPlot.pdf';
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
                %*boxAndWhisker
            ods pdf close;

            ods graphics on /
                reset = all
                border = no
                width = 10in
                height = 7.5in
                imagename = 'boxAndWhiskerPlot'
                imagefmt = png
                outputfmt = png;
            ods listing
                gpath = 'output';

                %*boxAndWhisker

        ods results;

    /*--------------------------------------------------------------------------------------------\
      Violin plot
    \--------------------------------------------------------------------------------------------*/

        %*violinPlot
            (data              = test
            ,outcomeVar        = Outcome
            ,outPath           = output
            ,outName           = violinPlotExample
            ,widthMultiplier   = 5
            );

        %*violinPlot
            (data              = cars
            ,outcomeVar        = Horsepower
            ,outPath           = output
            ,outName           = violinPlot
            ,widthMultiplier   = .1
            ,jitterYN          = Yes
            ,quartileYN        = Yes
            ,quartileSymbolsYN = No
            ,meanYN            = Yes
            ,trendLineYN       = No
            ,trendStatistic    = Median
            );

        %*violinPlot
            (data              = cars
            ,outcomeVar        = Horsepower
            ,outPath           = output
            ,outName           = violinPlot
            ,widthMultiplier   = .1
            );

        %violinPlot
            (data              = cars
            ,outcomeVar        = Horsepower
            ,outPath           = output
            ,outName           = violinPlotGrouped
            ,groupVar          = Cylinders
            ,widthMultiplier   = .1
            ,trendLineYN       = Yes
            ,trendStatistic    = Mean
            );

        data forStreamGraph;
            set kde;
        run;

        %*violinPlot
            (data              = cars
            ,outcomeVar        = Horsepower
            ,outPath           = output
            ,outName           = violinPlotPaneledAndGrouped
            ,groupVar          = Cylinders
            ,panelVar          = Origin
            ,widthMultiplier   = .1
            );

/*------------------------------------------------------------------------------------------------\
  Cleanup
\------------------------------------------------------------------------------------------------*/

    %sysexec del SGPlot.*;
    %sysexec del SGPanel.*;
    %sysexec del violinPlotImage.pdf;

/*------------------------------------------------------------------------------------------------\
  Stream graph
\------------------------------------------------------------------------------------------------*/

    proc sql;
        create table kdeStack as
            select groupVar, value, density, min(value) as minValue, max(value) as maxValue
                from forStreamGraph (where = (groupVar = 1))
          outer union corr
            select groupVar, value, density, min(value) as minValue, max(value) as maxValue
                from forStreamGraph (where = (groupVar = 2))
          outer union corr
            select groupVar, value, density, min(value) as minValue, max(value) as maxValue
                from forStreamGraph (where = (groupVar = 3))
        order by value;

        select min(value), max(value)
          into :minValue, :maxValue
            from kde;
    quit;

    data streamGraph;
        set kdeStack;
        by value;

        retain density1-density3;
        select (groupVar);
                when (1) density1 = density;
                when (2) density2 = density;
                when (3) density3 = density;
            otherwise;
        end;

        if value = minValue or value = maxValue then call missing(density1, density2, density3);

        if groupVar = 1 then do;
            lower = 0;
            upper = density;
        end;
        else if groupVar = 2 then do;
            lower = max(0, density1);
            upper = density + lower;
        end;
        else if groupVar = 3 then do;
            lower = max(0, density1) + max(0, density2);
            upper = density + lower;
        end;
    run;

    ods graphics /
        imagename = 'streamGraph';

        proc sgplot nocycleattrs noautolegend
            data = streamGraph;

            band
                x = value
                lower = lower
                upper = upper / fill outline
                    group = groupVar
                    lineattrs = (
                        pattern = solid
                        color = black);
        run;

/*------------------------------------------------------------------------------------------------\
  Side-by-side density curves
\------------------------------------------------------------------------------------------------*/

    /*to be continued*/