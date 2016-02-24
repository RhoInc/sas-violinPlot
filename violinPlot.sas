/*----------------------- Copyright 2016, Rho, Inc.  All rights reserved. ------------------------\

  Program:    violinPlot.sas

    Purpose:  Generate violin plots in SAS

    Output:   violinPlot.(pdf png sas)asdf

    /-------------------------------------------------------------------------------------------------\
      Macro parameters
    \-------------------------------------------------------------------------------------------------/

        [REQUIRED]

            data:           input dataset
            outcomeVar:     continuous outcome variable

        [optional]

            groupVar:       categorical grouping variable
            panelVar:       categorical panelling variable
            byVar:          categorical BY variable
            widthMultiplier:width coeffecient
            trendLineYN:    connect means between group values?

/-------------------------------------------------------------------------------------------------\
  Program history:
\-------------------------------------------------------------------------------------------------/

    Date        Programmer          Description
    ----------  ------------------  --------------------------------------------------------------
    2016-02-02  Spencer Childress   Create

\------------------------------------------------------------------------------------------------*/

%macro violinPlot
    (data            = 
    ,outcomeVar      = 
    ,groupVar        = 
    ,panelVar        = 
    ,byVar           = 
    ,widthMultiplier = 1
    ,trendLineYN     = Yes
    ) / minoperator;

    %if &data            = %then %goto exit;
    %if &outcomeVar      = %then %goto exit;
    %if &groupVar        = %then %goto exit;
    %if &widthMultiplier = %then %let  widthMuliplier = 1;

    /*-----------------------------------------------------------------------------------------------*/
    /* Data manipulation                                                                             */
    /*-----------------------------------------------------------------------------------------------*/

        proc sort data = &data (keep  = &byVar &panelVar &groupVar &outcomeVar
                                where = (&outcomeVar gt .z))
                   out = _inputData_;
            by &groupVar &outcomeVar;
        data inputData (drop = groupVarValues);
            retain &byVar &panelVar &groupVar &outcomeVar;
               set _inputData_ end = eof;
                by &groupVar;

            length groupVarValues $9999;
            retain groupVarValues;

            outcomeVar = &outcomeVar*&widthMultiplier;

            if first.&groupVar then do;
                groupVar   + 1;
                groupVarValues = catx('|', groupVarValues, &groupVar);
            end;

            if eof then do;
                                       call symputx('nGroupVarValues', strip(put(groupVar, 8.)));
                                       call symputx(' groupVarValues', groupVarValues);
                                       call symputx('outcomeVarLabel', coalescec(vlabel(&outcomeVar), vname(&outcomeVar)));
                                       call symputx('  groupVarLabel', coalescec(vlabel(  &groupVar), vname(  &groupVar)));
                %if &panelVar ne %then call symputx('  panelVarLabel', coalescec(vlabel(  &panelVar), vname(  &panelVar)));;
                %if    &byVar ne %then call symputx('     byVarLabel', coalescec(vlabel(     &byVar), vname(     &byVar)));;
            end;
        run;

                               %put %str(NOTE- Outcome:          &outcomeVarLabel);
                               %put %str(NOTE- Group by:         &groupVarLabel);
        %if &panelVar ne %then %put %str(NOTE- Panel by:         &panelVarLabel);
        %if    &byVar ne %then %put %str(NOTE- Process by:       &byVarLabel);
                               %put %str(NOTE- Number of groups: &nGroupVarValues);
                               %put %str(NOTE- Group values:     &groupVarValues);

    /*-----------------------------------------------------------------------------------------------*/
    /* Formats                                                                                       */
    /*-----------------------------------------------------------------------------------------------*/

        proc format;
            value groupVar
                %do i = 1 %to %scan(&nGroupVarValues, -1);
                    %sysevalf(&i/2 - .25) -< %sysevalf(&i/2 + .25) = %scan(&groupVarValues, &i, |)
                %end;
                other        = ' '
            ;
        run;

    /*-----------------------------------------------------------------------------------------------*/
    /* Statistics                                                                                    */
    /*-----------------------------------------------------------------------------------------------*/

        /*-------------------------------------------------------------------------------------------*/
        /* Kernel density estimation                                                                 */
        /*-------------------------------------------------------------------------------------------*/

            proc sort data = inputData;
                by &byVar &panelVar &groupVar;
            proc kde data = inputData;
                by     &byVar &panelVar &groupVar groupVar;
                univar outcomeVar / noprint
                    out = KDE;
            run;

        /*-------------------------------------------------------------------------------------------*/
        /* Descriptive statistics                                                                    */
        /*-------------------------------------------------------------------------------------------*/

            proc means noprint nway
                data = inputData;
                class  &byVar &panelVar &groupVar groupVar;
                var    &outcomeVar;
                output
                    out    = statistics
                    mean   = mean
                    p25    = quartile1
                    median = median
                    p75    = quartile3;
            run;

        /*-------------------------------------------------------------------------------------------*/
        /* Merge kernel density estimates and descriptive statistics to assign quartiles             */
        /*-------------------------------------------------------------------------------------------*/

            proc sql;
                create table KDEstatistics as
                    select a.*,

                          density  + b.groupVar/2 as upperBand,
                        (-density) + b.groupVar/2 as lowerBand,
                        value/&widthMultiplier    as     yBand,
                        case when              calculated yBand le quartile1 then  25 + 100*b.groupVar
                             when quartile1 lt calculated yBand le median    then  50 + 100*b.groupVar
                             when median    lt calculated yBand le quartile3 then  75 + 100*b.groupVar
                                                                             else 100 + 100*b.groupVar
                         end as quartile

                         from    KDE a
                             inner join
                                 statistics b
                             on %if &byVar    ne %then a.&byVar    = b.&byVar and;
                                %if &panelVar ne %then a.&panelVar = b.&panelVar and;
                                a.&groupVar = b.&groupVar
                order by %if &byVar    ne %then &byVar,;
                         %if &panelVar ne %then &panelVar,;
                                                &groupVar,
                                                 yBand;

                create table inputDataStatistics as
                    select a.*,
                        case when              &outcomeVar le quartile1 then  25 + 100*b.groupVar
                             when quartile1 lt &outcomeVar le median    then  50 + 100*b.groupVar
                             when median    lt &outcomeVar le quartile3 then  75 + 100*b.groupVar
                                                                        else 100 + 100*b.groupVar
                         end as quartile,
                        case when              &outcomeVar le quartile1 then b.groupVar/2 + ifn(mod(monotonic(), 2), 1, -1)*ranuni(2357)/30
                             when quartile1 lt &outcomeVar le median    then b.groupVar/2 + ifn(mod(monotonic(), 2), 1, -1)*ranuni(2357)/15
                             when median    lt &outcomeVar le quartile3 then b.groupVar/2 + ifn(mod(monotonic(), 2), 1, -1)*ranuni(2357)/15
                                                                        else b.groupVar/2 + ifn(mod(monotonic(), 2), 1, -1)*ranuni(2357)/30
                         end as jitter

                         from    inputData a
                             inner join
                                 statistics b
                             on %if &byVar    ne %then a.&byVar    = b.&byVar and;
                                %if &panelVar ne %then a.&panelVar = b.&panelVar and;
                                a.&groupVar = b.&groupVar
                order by %if &byVar    ne %then &byVar,;
                         %if &panelVar ne %then &panelVar,;
                                                &groupVar,
                                                 &outcomeVar;
            quit;

        /*-------------------------------------------------------------------------------------------*/
        /* Stack kernel density estimates and descriptive statistics with input dataset              */
        /*-------------------------------------------------------------------------------------------*/

            data fin;
                set       KDEstatistics (in = a)
                             statistics (in = b)
                    inputDataStatistics (in = c);

                groupVar_div_2 = groupVar/2;
            run;

            proc sql noprint;
                select
                    ceil(max(&outcomeVar))
                  into :max trimmed
                    from inputData;
            quit;

    /*-----------------------------------------------------------------------------------------------*/
    /* Figure generation                                                                             */
    /*-----------------------------------------------------------------------------------------------*/

        proc template;
           define style styles.violin;
                parent = styles.printer;
                    %do i = 1 %to &nGroupVarValues;
                        style GraphData%eval(&i*4 - 3) / color = cxc6dbef;
                        style GraphData%eval(&i*4 - 2) / color = cx9ecae1;
                        style GraphData%eval(&i*4 - 1) / color = cx6baed6;
                        style GraphData%eval(&i*4    ) / color = cx3182bd;
                    %end;
           end;
        run;

        options orientation = landscape nodate;

        title1 j = c "&outcomeVarLabel";
        title2 j = c "Paneled by &panelVarLabel";

        ods listing
            gpath = "%sysfunc(pathname(work))"
            style = styles.violin;

        ods results off;
            ods pdf
                file  = "violinPlot.pdf"
                style = styles.violin;
                ods graphics on /
                    reset        = all
                    border       = no
                    width        = 10.5 in
                    height       =  8   in
                    imagefmt     = pdf
                    outputfmt    = pdf;

                    proc sgpanel data = fin nocycleattrs noautolegend;
                        format
                            lowerBand upperBand groupVar_div_2 jitter groupVar.;
                        panelby
                            &panelVar /
                                novarname
                                rows    = 1
                                columns = 3;
                        band
                            y = yBand
                            lower = lowerBand
                            upper = upperBand /
                                fill outline
                                group = quartile
                                lineattrs = (
                                    pattern = solid
                                    color = black);
                        scatter
                            x = groupVar_div_2
                            y = quartile1 /
                                markerattrs = (
                                    symbol = circleFilled
                                    size = 8px
                                    color = white);
                        scatter
                            x = groupVar_div_2
                            y = median /
                                markerattrs = (
                                    symbol = circleFilled
                                    size = 12px
                                    color = white);
                        scatter
                            x = groupVar_div_2
                            y = quartile3 /
                                markerattrs = (
                                    symbol = circleFilled
                                    size = 8px
                                    color = white);
                        %if &trendLineYN = Yes %then
                        series
                            x = groupVar_div_2
                            y = mean /
                                lineattrs = (
                                    color = red
                                    thickness = 2px);;
                        scatter
                            x = groupVar_div_2
                            y = mean /
                                markerattrs = (
                                    symbol = circleFilled
                                    size = 12px
                                    color = red);
                        scatter
                            x = jitter
                            y = &outcomeVar /
                                markerattrs = (
                                    symbol = circle
                                    size = 8px
                                    color = black);
                        rowaxis
                            label  = "&outcomeVarLabel"
                            values = (0 to &max);
                        colaxis
                            label   = "&groupVarLabel"
                            display = (noticks)
                            values  = (0 to %sysevalf(%scan(&nGroupVarValues, -1)/2 + .5) by .5);
                    run;

                ods graphics off;
            ods pdf close;
        ods results;

    %exit:

%mend  violinPlot;
