/*----------------------- Copyright 2019, Rho, Inc.  All rights reserved. ------------------------\

  Study:        sas-violinPlot

    Program:    runViolinPlot.sas

      Purpose:  Generate example violin plots

      Input:    SASHELP.CARS
                <repository directory>\violinPlot.sas

      Output:   <repository directory>\test\violinPlot.(pdf png)

      Macros:   %violinPlot

  /-----------------------------------------------------------------------------------------------\
    Program History:
  \-----------------------------------------------------------------------------------------------/

    Date        Programmer          Description
    ----------  ------------------  ---------------------------------------------------------------
    2019-01-17  Spencer Childress   Create

\------------------------------------------------------------------------------------------------*/

   *Set the working drive and directory below before running program.;
    %sysexec <repository drive>;
    %sysexec cd "<repository directory>";
    %*sysexec H:;
    %*sysexec cd "test\sas-violinPlot";

    ods listing
        gpath = 'output';

    options threads
        compress = char;

    %include 'src\violinPlot.sas';

/*------------------------------------------------------------------------------------------------\
  Data manipulation
\------------------------------------------------------------------------------------------------*/

    data cars;
        set sashelp.cars (
                where = (
                    cylinders in (4 6 8)
                )
            );
    run;

    proc sort
        data = cars;
        by Origin Cylinders Horsepower;
    run;

/*--------------------------------------------------------------------------------------------\
  Violin plots
\--------------------------------------------------------------------------------------------*/

    %violinPlot(
        data              = cars,
        outcomeVar        = Horsepower,
        groupVar          = Cylinders,
        panelVar          = Origin,
        outPath           = test,
        outName           = violinPlot,
        widthMultiplier   = .1,
        quartileYN        = ,
        meanYN            = ,
        trendLineYN       = ,
        jitterYN          = ,
        quartileSymbolsYN = ,
        trendStatistic    = 
    );

/*------------------------------------------------------------------------------------------------\
  Cleanup
\------------------------------------------------------------------------------------------------*/

    %sysexec del SGPlot.*;
    %sysexec del SGPanel.*;
    %sysexec del violinPlotImage.pdf;
