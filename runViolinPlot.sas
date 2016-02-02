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

                                   %sysexec <repository drive>;
                               %sysexec cd "<repository diretory>";
                                     ods listing gpath = ".";

                                  options compress = char threads
                                          linesize = 104
                                          pagesize =  79;

/*------------------------------------------------------------------------------------------------\
  Data
\------------------------------------------------------------------------------------------------*/

    proc sql;
          select catx('|', DriveTrain, put(Cylinders, 8.)) as DriveTrainCylinders, count(1) as freq
            into :DriveTrainCylinders separated by '" "',
                 :freqs               separated by  ' '
              from sashelp.cars (where = (1))
          group by DriveTrainCylinders
        having freq gt 4;
    quit;

    data cars;
        set sashelp.cars (where = (catx('|', DriveTrain, put(Cylinders, 8.)) in ("&DriveTrainCylinders")));
    run;

/*------------------------------------------------------------------------------------------------\
  Figure
\------------------------------------------------------------------------------------------------*/

        %include 'violinPlot.sas';
        %violinPlot
            (data            = cars
            ,outcomeVar      = Horsepower
            ,groupVar        = DriveTrain
            ,panelVar        = Cylinders
            ,byVar           = 
            ,widthMultiplier = .1
            ,trendLineYN     = Yes
            );
