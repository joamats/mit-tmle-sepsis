
* TMLE Project 
* Stata code for logistic regression only



* LogReg on race and ventilation
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor // across all SOFA groups
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 1 // SOFA 0-5
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 2 // SOFA 6-10
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 3 // SOFA 11-15
logistic ventilation white age female i.year SOFA i.CCIgroup rrt pressor if SOFA group == 4 // SOFA >15

* LogReg on race and renal replacement therapy
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor // across all SOFA groups
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 1 // SOFA 0-5
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 2 // SOFA 6-10
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 3 // SOFA 11-15
logistic rrt white age female i.year SOFA i.CCIgroup ventilation pressor if SOFA group == 4 // SOFA >15


* LogReg on race and vasopressors
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt // across all SOFA groups
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 1 // SOFA 0-5
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 2 // SOFA 6-10
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 3 // SOFA 11-15
logistic pressor white age female i.year SOFA i.CCIgroup ventilation rrt if SOFA group == 4 // SOFA >15


