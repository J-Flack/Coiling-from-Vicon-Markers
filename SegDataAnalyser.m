t_p_e=[segData(1).positive_rising.torsion;segData(2).positive_rising.torsion;segData(3).positive_rising.torsion;segData(4).positive_rising.torsion;segData(5).positive_rising.torsion;segData(6).positive_rising.torsion;segData(7).positive_rising.torsion; segData(8).positive_rising.torsion; segData(9).positive_rising.torsion; segData(10).positive_rising.torsion]' ;

dtz_p_e=[segData(1).positive_rising.dtz; segData(2).positive_rising.dtz; segData(3).positive_rising.dtz; segData(4).positive_rising.dtz; segData(5).positive_rising.dtz; segData(6).positive_rising.dtz; segData(7).positive_rising.dtz; segData(8).positive_rising.dtz; segData(9).positive_rising.dtz; segData(10).positive_rising.dtz] ;

% DG_p=[segData(1).positive_rising.Wr.DirectGauss segData(2).positive_rising.Wr.DirectGauss segData(3).positive_rising.Wr.DirectGauss segData(4).positive_rising.Wr.DirectGauss segData(5).positive_rising.Wr.DirectGauss segData(6).positive_rising.Wr.DirectGauss segData(7).positive_rising.Wr.DirectGauss segData(8).positive_rising.Wr.DirectGauss segData(9).positive_rising.Wr.DirectGauss segData(10).positive_rising.Wr.DirectGauss] 
% 
% F_p=[segData(1).positive_rising.Wr.Fuller  segData(2).positive_rising.Wr.Fuller  segData(3).positive_rising.Wr.Fuller  segData(4).positive_rising.Wr.Fuller  segData(5).positive_rising.Wr.Fuller  segData(6).positive_rising.Wr.Fuller  segData(7).positive_rising.Wr.Fuller  segData(8).positive_rising.Wr.Fuller  segData(9).positive_rising.Wr.Fuller  segData(10).positive_rising.Wr.Fuller ] 
% 
% PPN_p=[segData(1).positive_rising.Wr.PolarPriorNeukirch segData(2).positive_rising.Wr.PolarPriorNeukirch segData(3).positive_rising.Wr.PolarPriorNeukirch segData(4).positive_rising.Wr.PolarPriorNeukirch segData(5).positive_rising.Wr.PolarPriorNeukirch segData(6).positive_rising.Wr.PolarPriorNeukirch segData(7).positive_rising.Wr.PolarPriorNeukirch segData(8).positive_rising.Wr.PolarPriorNeukirch segData(9).positive_rising.Wr.PolarPriorNeukirch segData(10).positive_rising.Wr.PolarPriorNeukirch] 
% 
% S_p=[segData(1).positive_rising.Wr.Starostin  segData(2).positive_rising.Wr.Starostin  segData(3).positive_rising.Wr.Starostin  segData(4).positive_rising.Wr.Starostin  segData(5).positive_rising.Wr.Starostin  segData(6).positive_rising.Wr.Starostin  segData(7).positive_rising.Wr.Starostin  segData(8).positive_rising.Wr.Starostin  segData(9).positive_rising.Wr.Starostin  segData(10).positive_rising.Wr.Starostin ] 

ACN_p_e=[segData(1).positive_rising.Wr.ACN  segData(2).positive_rising.Wr.ACN  segData(3).positive_rising.Wr.ACN  segData(4).positive_rising.Wr.ACN  segData(5).positive_rising.Wr.ACN  segData(6).positive_rising.Wr.ACN  segData(7).positive_rising.Wr.ACN  segData(8).positive_rising.Wr.ACN  segData(9).positive_rising.Wr.ACN  segData(10).positive_rising.Wr.ACN ] ;

GSN_p_e=[segData(1).positive_rising.Wr.GaussSumNaive  segData(2).positive_rising.Wr.GaussSumNaive  segData(3).positive_rising.Wr.GaussSumNaive  segData(4).positive_rising.Wr.GaussSumNaive  segData(5).positive_rising.Wr.GaussSumNaive  segData(6).positive_rising.Wr.GaussSumNaive  segData(7).positive_rising.Wr.GaussSumNaive  segData(8).positive_rising.Wr.GaussSumNaive  segData(9).positive_rising.Wr.GaussSumNaive  segData(10).positive_rising.Wr.GaussSumNaive ] ;

% GSM_p=[segData(1).positive_rising.Wr.GaussSumMidpoint  segData(2).positive_rising.Wr.GaussSumMidpoint  segData(3).positive_rising.Wr.GaussSumMidpoint  segData(4).positive_rising.Wr.GaussSumMidpoint  segData(5).positive_rising.Wr.GaussSumMidpoint  segData(6).positive_rising.Wr.GaussSumMidpoint  segData(7).positive_rising.Wr.GaussSumMidpoint  segData(8).positive_rising.Wr.GaussSumMidpoint  segData(9).positive_rising.Wr.GaussSumMidpoint  segData(10).positive_rising.Wr.GaussSumMidpoint ] 
% 
% TIN_p=[segData(1).positive_rising.Wr.TangentIncrementNaive  segData(2).positive_rising.Wr.TangentIncrementNaive  segData(3).positive_rising.Wr.TangentIncrementNaive  segData(4).positive_rising.Wr.TangentIncrementNaive  segData(5).positive_rising.Wr.TangentIncrementNaive  segData(6).positive_rising.Wr.TangentIncrementNaive  segData(7).positive_rising.Wr.TangentIncrementNaive  segData(8).positive_rising.Wr.TangentIncrementNaive  segData(9).positive_rising.Wr.TangentIncrementNaive  segData(10).positive_rising.Wr.TangentIncrementNaive ] 
% 
% GLQ_p=[segData(1).positive_rising.Wr.GaussLegendreQuad  segData(2).positive_rising.Wr.GaussLegendreQuad  segData(3).positive_rising.Wr.GaussLegendreQuad  segData(4).positive_rising.Wr.GaussLegendreQuad  segData(5).positive_rising.Wr.GaussLegendreQuad  segData(6).positive_rising.Wr.GaussLegendreQuad  segData(7).positive_rising.Wr.GaussLegendreQuad  segData(8).positive_rising.Wr.GaussLegendreQuad  segData(9).positive_rising.Wr.GaussLegendreQuad  segData(10).positive_rising.Wr.GaussLegendreQuad ] 
% 
% TGA_p=[segData(1).positive_rising.Wr.TantrixGeodesicAdv  segData(2).positive_rising.Wr.TantrixGeodesicAdv  segData(3).positive_rising.Wr.TantrixGeodesicAdv  segData(4).positive_rising.Wr.TantrixGeodesicAdv  segData(5).positive_rising.Wr.TantrixGeodesicAdv  segData(6).positive_rising.Wr.TantrixGeodesicAdv  segData(7).positive_rising.Wr.TantrixGeodesicAdv  segData(8).positive_rising.Wr.TantrixGeodesicAdv  segData(9).positive_rising.Wr.TantrixGeodesicAdv  segData(10).positive_rising.Wr.TantrixGeodesicAdv ] 
% 
% RM_p=[segData(1).positive_rising.Wr.RossettoMaggs2003  segData(2).positive_rising.Wr.RossettoMaggs2003  segData(3).positive_rising.Wr.RossettoMaggs2003  segData(4).positive_rising.Wr.RossettoMaggs2003  segData(5).positive_rising.Wr.RossettoMaggs2003  segData(6).positive_rising.Wr.RossettoMaggs2003  segData(7).positive_rising.Wr.RossettoMaggs2003  segData(8).positive_rising.Wr.RossettoMaggs2003  segData(9).positive_rising.Wr.RossettoMaggs2003  segData(10).positive_rising.Wr.RossettoMaggs2003 ] 
% 
% OIL_p=[segData(1).positive_rising.Wr.OpenInfinityLegacy  segData(2).positive_rising.Wr.OpenInfinityLegacy  segData(3).positive_rising.Wr.OpenInfinityLegacy  segData(4).positive_rising.Wr.OpenInfinityLegacy  segData(5).positive_rising.Wr.OpenInfinityLegacy  segData(6).positive_rising.Wr.OpenInfinityLegacy  segData(7).positive_rising.Wr.OpenInfinityLegacy  segData(8).positive_rising.Wr.OpenInfinityLegacy  segData(9).positive_rising.Wr.OpenInfinityLegacy  segData(10).positive_rising.Wr.OpenInfinityLegacy ] 
% 
% TIA_p=[segData(1).positive_rising.Wr.TangentIndicatrixAntipodal  segData(2).positive_rising.Wr.TangentIndicatrixAntipodal  segData(3).positive_rising.Wr.TangentIndicatrixAntipodal  segData(4).positive_rising.Wr.TangentIndicatrixAntipodal  segData(5).positive_rising.Wr.TangentIndicatrixAntipodal  segData(6).positive_rising.Wr.TangentIndicatrixAntipodal  segData(7).positive_rising.Wr.TangentIndicatrixAntipodal  segData(8).positive_rising.Wr.TangentIndicatrixAntipodal  segData(9).positive_rising.Wr.TangentIndicatrixAntipodal  segData(10).positive_rising.Wr.TangentIndicatrixAntipodal ] 
% 
% SCA_p=[segData(1).positive_rising.Wr.SphericalClosureAveraged  segData(2).positive_rising.Wr.SphericalClosureAveraged  segData(3).positive_rising.Wr.SphericalClosureAveraged  segData(4).positive_rising.Wr.SphericalClosureAveraged  segData(5).positive_rising.Wr.SphericalClosureAveraged  segData(6).positive_rising.Wr.SphericalClosureAveraged  segData(7).positive_rising.Wr.SphericalClosureAveraged  segData(8).positive_rising.Wr.SphericalClosureAveraged  segData(9).positive_rising.Wr.SphericalClosureAveraged  segData(10).positive_rising.Wr.SphericalClosureAveraged ] 
% 
% PPCA_p=[segData(1).positive_rising.Wr.PolarPCA  segData(2).positive_rising.Wr.PolarPCA  segData(3).positive_rising.Wr.PolarPCA  segData(4).positive_rising.Wr.PolarPCA  segData(5).positive_rising.Wr.PolarPCA  segData(6).positive_rising.Wr.PolarPCA  segData(7).positive_rising.Wr.PolarPCA  segData(8).positive_rising.Wr.PolarPCA  segData(9).positive_rising.Wr.PolarPCA  segData(10).positive_rising.Wr.PolarPCA ] 

t_n_e=[segData(1).negative_rising.torsion;segData(2).negative_rising.torsion;segData(3).negative_rising.torsion;segData(4).negative_rising.torsion;segData(5).negative_rising.torsion;segData(6).negative_rising.torsion;segData(7).negative_rising.torsion; segData(8).negative_rising.torsion; segData(9).negative_rising.torsion; segData(10).negative_rising.torsion]' ;

dtz_n_e=[segData(1).negative_rising.dtz; segData(2).negative_rising.dtz; segData(3).negative_rising.dtz; segData(4).negative_rising.dtz; segData(5).negative_rising.dtz; segData(6).negative_rising.dtz; segData(7).negative_rising.dtz; segData(8).negative_rising.dtz; segData(9).negative_rising.dtz; segData(10).negative_rising.dtz] ;

% DG_p=[segData(1).negative_rising.Wr.DirectGauss segData(2).negative_rising.Wr.DirectGauss segData(3).negative_rising.Wr.DirectGauss segData(4).negative_rising.Wr.DirectGauss segData(5).negative_rising.Wr.DirectGauss segData(6).negative_rising.Wr.DirectGauss segData(7).negative_rising.Wr.DirectGauss segData(8).negative_rising.Wr.DirectGauss segData(9).negative_rising.Wr.DirectGauss segData(10).negative_rising.Wr.DirectGauss] 
% 
% F_p=[segData(1).negative_rising.Wr.Fuller  segData(2).negative_rising.Wr.Fuller  segData(3).negative_rising.Wr.Fuller  segData(4).negative_rising.Wr.Fuller  segData(5).negative_rising.Wr.Fuller  segData(6).negative_rising.Wr.Fuller  segData(7).negative_rising.Wr.Fuller  segData(8).negative_rising.Wr.Fuller  segData(9).negative_rising.Wr.Fuller  segData(10).negative_rising.Wr.Fuller ] 
% 
% PPN_p=[segData(1).negative_rising.Wr.PolarPriorNeukirch segData(2).negative_rising.Wr.PolarPriorNeukirch segData(3).negative_rising.Wr.PolarPriorNeukirch segData(4).negative_rising.Wr.PolarPriorNeukirch segData(5).negative_rising.Wr.PolarPriorNeukirch segData(6).negative_rising.Wr.PolarPriorNeukirch segData(7).negative_rising.Wr.PolarPriorNeukirch segData(8).negative_rising.Wr.PolarPriorNeukirch segData(9).negative_rising.Wr.PolarPriorNeukirch segData(10).negative_rising.Wr.PolarPriorNeukirch] 
% 
% S_p=[segData(1).negative_rising.Wr.Starostin  segData(2).negative_rising.Wr.Starostin  segData(3).negative_rising.Wr.Starostin  segData(4).negative_rising.Wr.Starostin  segData(5).negative_rising.Wr.Starostin  segData(6).negative_rising.Wr.Starostin  segData(7).negative_rising.Wr.Starostin  segData(8).negative_rising.Wr.Starostin  segData(9).negative_rising.Wr.Starostin  segData(10).negative_rising.Wr.Starostin ] 

ACN_n_e=[segData(1).negative_rising.Wr.ACN  segData(2).negative_rising.Wr.ACN  segData(3).negative_rising.Wr.ACN  segData(4).negative_rising.Wr.ACN  segData(5).negative_rising.Wr.ACN  segData(6).negative_rising.Wr.ACN  segData(7).negative_rising.Wr.ACN  segData(8).negative_rising.Wr.ACN  segData(9).negative_rising.Wr.ACN  segData(10).negative_rising.Wr.ACN ] ;

GSN_n_e=[segData(1).negative_rising.Wr.GaussSumNaive  segData(2).negative_rising.Wr.GaussSumNaive  segData(3).negative_rising.Wr.GaussSumNaive  segData(4).negative_rising.Wr.GaussSumNaive  segData(5).negative_rising.Wr.GaussSumNaive  segData(6).negative_rising.Wr.GaussSumNaive  segData(7).negative_rising.Wr.GaussSumNaive  segData(8).negative_rising.Wr.GaussSumNaive  segData(9).negative_rising.Wr.GaussSumNaive  segData(10).negative_rising.Wr.GaussSumNaive ] ;
close all
% figure
% plot(t_p_e,dtz_p_e)
% title('positive')
% 
% figure
% plot(t_n_e,dtz_n_e)
% title('negative')
% GSM_p=[segData(1).negative_rising.Wr.GaussSumMidpoint  segData(2).negative_rising.Wr.GaussSumMidpoint  segData(3).negative_rising.Wr.GaussSumMidpoint  segData(4).negative_rising.Wr.GaussSumMidpoint  segData(5).negative_rising.Wr.GaussSumMidpoint  segData(6).negative_rising.Wr.GaussSumMidpoint  segData(7).negative_rising.Wr.GaussSumMidpoint  segData(8).negative_rising.Wr.GaussSumMidpoint  segData(9).negative_rising.Wr.GaussSumMidpoint  segData(10).negative_rising.Wr.GaussSumMidpoint ] 
% 
% TIN_p=[segData(1).negative_rising.Wr.TangentIncrementNaive  segData(2).negative_rising.Wr.TangentIncrementNaive  segData(3).negative_rising.Wr.TangentIncrementNaive  segData(4).negative_rising.Wr.TangentIncrementNaive  segData(5).negative_rising.Wr.TangentIncrementNaive  segData(6).negative_rising.Wr.TangentIncrementNaive  segData(7).negative_rising.Wr.TangentIncrementNaive  segData(8).negative_rising.Wr.TangentIncrementNaive  segData(9).negative_rising.Wr.TangentIncrementNaive  segData(10).negative_rising.Wr.TangentIncrementNaive ] 
% 
% GLQ_p=[segData(1).negative_rising.Wr.GaussLegendreQuad  segData(2).negative_rising.Wr.GaussLegendreQuad  segData(3).negative_rising.Wr.GaussLegendreQuad  segData(4).negative_rising.Wr.GaussLegendreQuad  segData(5).negative_rising.Wr.GaussLegendreQuad  segData(6).negative_rising.Wr.GaussLegendreQuad  segData(7).negative_rising.Wr.GaussLegendreQuad  segData(8).negative_rising.Wr.GaussLegendreQuad  segData(9).negative_rising.Wr.GaussLegendreQuad  segData(10).negative_rising.Wr.GaussLegendreQuad ] 
% 
% TGA_p=[segData(1).negative_rising.Wr.TantrixGeodesicAdv  segData(2).negative_rising.Wr.TantrixGeodesicAdv  segData(3).negative_rising.Wr.TantrixGeodesicAdv  segData(4).negative_rising.Wr.TantrixGeodesicAdv  segData(5).negative_rising.Wr.TantrixGeodesicAdv  segData(6).negative_rising.Wr.TantrixGeodesicAdv  segData(7).negative_rising.Wr.TantrixGeodesicAdv  segData(8).negative_rising.Wr.TantrixGeodesicAdv  segData(9).negative_rising.Wr.TantrixGeodesicAdv  segData(10).negative_rising.Wr.TantrixGeodesicAdv ] 
% 
% RM_p=[segData(1).negative_rising.Wr.RossettoMaggs2003  segData(2).negative_rising.Wr.RossettoMaggs2003  segData(3).negative_rising.Wr.RossettoMaggs2003  segData(4).negative_rising.Wr.RossettoMaggs2003  segData(5).negative_rising.Wr.RossettoMaggs2003  segData(6).negative_rising.Wr.RossettoMaggs2003  segData(7).negative_rising.Wr.RossettoMaggs2003  segData(8).negative_rising.Wr.RossettoMaggs2003  segData(9).negative_rising.Wr.RossettoMaggs2003  segData(10).negative_rising.Wr.RossettoMaggs2003 ] 
% 
% OIL_p=[segData(1).negative_rising.Wr.OpenInfinityLegacy  segData(2).negative_rising.Wr.OpenInfinityLegacy  segData(3).negative_rising.Wr.OpenInfinityLegacy  segData(4).negative_rising.Wr.OpenInfinityLegacy  segData(5).negative_rising.Wr.OpenInfinityLegacy  segData(6).negative_rising.Wr.OpenInfinityLegacy  segData(7).negative_rising.Wr.OpenInfinityLegacy  segData(8).negative_rising.Wr.OpenInfinityLegacy  segData(9).negative_rising.Wr.OpenInfinityLegacy  segData(10).negative_rising.Wr.OpenInfinityLegacy ] 
% 
% TIA_p=[segData(1).negative_rising.Wr.TangentIndicatrixAntipodal  segData(2).negative_rising.Wr.TangentIndicatrixAntipodal  segData(3).negative_rising.Wr.TangentIndicatrixAntipodal  segData(4).negative_rising.Wr.TangentIndicatrixAntipodal  segData(5).negative_rising.Wr.TangentIndicatrixAntipodal  segData(6).negative_rising.Wr.TangentIndicatrixAntipodal  segData(7).negative_rising.Wr.TangentIndicatrixAntipodal  segData(8).negative_rising.Wr.TangentIndicatrixAntipodal  segData(9).negative_rising.Wr.TangentIndicatrixAntipodal  segData(10).negative_rising.Wr.TangentIndicatrixAntipodal ] 
% 
% SCA_p=[segData(1).negative_rising.Wr.SphericalClosureAveraged  segData(2).negative_rising.Wr.SphericalClosureAveraged  segData(3).negative_rising.Wr.SphericalClosureAveraged  segData(4).negative_rising.Wr.SphericalClosureAveraged  segData(5).negative_rising.Wr.SphericalClosureAveraged  segData(6).negative_rising.Wr.SphericalClosureAveraged  segData(7).negative_rising.Wr.SphericalClosureAveraged  segData(8).negative_rising.Wr.SphericalClosureAveraged  segData(9).negative_rising.Wr.SphericalClosureAveraged  segData(10).negative_rising.Wr.SphericalClosureAveraged ] 
% 
% PPCA_p=[segData(1).negative_rising.Wr.PolarPCA  segData(2).negative_rising.Wr.PolarPCA  segData(3).negative_rising.Wr.PolarPCA  segData(4).negative_rising.Wr.PolarPCA  segData(5).negative_rising.Wr.PolarPCA  segData(6).negative_rising.Wr.PolarPCA  segData(7).negative_rising.Wr.PolarPCA  segData(8).negative_rising.Wr.PolarPCA  segData(9).negative_rising.Wr.PolarPCA  segData(10).negative_rising.Wr.PolarPCA ] 

ACN_p_e_n=[segData(1).positive_rising.Wr.ACN-max(segData(1).positive_rising.Wr.ACN)  segData(2).positive_rising.Wr.ACN-max(segData(2).positive_rising.Wr.ACN)  segData(3).positive_rising.Wr.ACN-max(segData(3).positive_rising.Wr.ACN)  segData(4).positive_rising.Wr.ACN-max(segData(4).positive_rising.Wr.ACN)  segData(5).positive_rising.Wr.ACN-max(segData(5).positive_rising.Wr.ACN)  segData(6).positive_rising.Wr.ACN-max(segData(6).positive_rising.Wr.ACN)  segData(7).positive_rising.Wr.ACN-max(segData(7).positive_rising.Wr.ACN)  segData(8).positive_rising.Wr.ACN-max(segData(8).positive_rising.Wr.ACN)  segData(9).positive_rising.Wr.ACN-max(segData(9).positive_rising.Wr.ACN)  segData(10).positive_rising.Wr.ACN-max(segData(10).positive_rising.Wr.ACN) ] ;
ACN_n_e_n=[segData(1).negative_rising.Wr.ACN-min(segData(1).negative_rising.Wr.ACN)  segData(2).negative_rising.Wr.ACN-min(segData(2).negative_rising.Wr.ACN)  segData(3).negative_rising.Wr.ACN-min(segData(3).negative_rising.Wr.ACN)  segData(4).negative_rising.Wr.ACN-min(segData(4).negative_rising.Wr.ACN)  segData(5).negative_rising.Wr.ACN-min(segData(5).negative_rising.Wr.ACN)  segData(6).negative_rising.Wr.ACN-min(segData(6).negative_rising.Wr.ACN)  segData(7).negative_rising.Wr.ACN-min(segData(7).negative_rising.Wr.ACN)  segData(8).negative_rising.Wr.ACN-min(segData(8).negative_rising.Wr.ACN)  segData(9).negative_rising.Wr.ACN-min(segData(9).negative_rising.Wr.ACN)  segData(10).negative_rising.Wr.ACN-min(segData(10).negative_rising.Wr.ACN) ] ;

% Example arrays (replace with your actual data)
A = t_n_e;
B = ACN_n_e_n;
C = dtz_n_e;

% Logical mask: keep elements where A >= 5
mask = A <= -8;

% Apply mask to all three arrays
A_f = A(mask);
B_f = B(mask);
C_f = C(mask);

%figure
%plot3(A_f,B_f,C_f)
%title('negative')


clc
fitResult = fit_torque_model(A_f, B_f, C_f)

%%
close all
figure
plot(t_p_e,dtz_p_e)
title('positive')

figure
plot(t_n_e,dtz_n_e)
title('negative')
%%
% Example arrays (replace with your actual data)
A = t_n_e;
B = ACN_n_e_n;
C = dtz_n_e;

% Logical mask: keep elements where A >= 5
mask = A <= -8;

% Apply mask to all three arrays
A_f = A(mask);
B_f = B(mask);
C_f = C(mask);

figure
plot3(A_f,B_f,C_f)
title('negative')
%%
% Example arrays (replace with your actual data)
A = t_p_e;
B = ACN_p_e;
C = dtz_p_e;

% Logical mask: keep elements where A >= 5
mask = A >= 7;

% Apply mask to all three arrays
A_f = A(mask);
B_f = B(mask);
C_f = C(mask);

figure
plot(A_f,B_f)
title('positive')
%%
clc
fitResult = fit_torque_model(t_p_e, ACN_p_e_n, dtz_p_e)
%%
clc
fitResult = fit_torque_model(t_n_e, ACN_n_e_n, dtz_n_e)
%%
clc
fitResult = fit_torque_model(A_f, B_f, C_f)