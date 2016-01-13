                                %include 'H:\Macros\gridReset.sas';
                      %gridReset(H:\Conferences\PharmaSUG\2016\violinPlot);
;                                                                                                 ;
                                  options compress = char threads
                                          linesize = 104
                                          pagesize =  79
                                          sasautos = (sasautos
                                                     ,'S:\BASESTAT\Autocall'
                                                     ,'H:\Macros');

/*-----------------------------------------------------------------------------------------------*/
/* Data                                                                                          */
/*-----------------------------------------------------------------------------------------------*/

    libname
        derive
        'S:\RhoFED\ITN\AsthmaAllergy\ITN043AD_Durham\Reports\Final\Data\Derive'
        access = readonly;

        data test;
            set derive.adtnss2 (where = (samp = 'S/I' and input(phase, 8.) ge 2000));
        run;

        %include 'H:\Macros\violinPlot.sas';
        %violinPlot
            (data            = test
            ,outcomeVar      = tnssaucp
            ,groupVar        = phase
            ,panelVar        = trt01p
            ,byVar           = 
            ,widthMultiplier = 1.4
            ,trendLineYN     = Yes
            );
