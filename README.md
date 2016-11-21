# sas-violinPlot
The sas-violinPlot library allows users to generate violin plots with SAS.  Check out the [wiki](https://github.com/RhoInc/sas-violinPlot/wiki) for more details.

![look, a wild violin plot!](https://github.com/RhoInc/sas-violinPlot/blob/master/output/violinPlotPaneledAndGrouped.png)

## Abstract
If you've ever seen a box-and-whiskers plot you were probably unimpressed.  It lives up to its name, providing a basic visualization of the distribution of an outcome: the interquartile range (the box), the minimum and maximum (the whiskers), the median, and maybe a few outliers if you’re (un)lucky.  Enter the violin plot.  This data visualization technique harnesses density estimates to describe the outcome’s distribution.  In other words the violin plot widens around larger clusters of values (the upper and lower bouts of a violin) and narrows around smaller clusters (the waist of the violin), delivering a nuanced visualization of an outcome.  With the power of SAS/GRAPH®, the savvy SAS® programmer can reproduce the statistics of the box-and-whiskers plot while offering improved data visualization through the addition of the probability density ‘violin’ curve.  This paper covers various SAS techniques required to produce violin plots.
