function [cutpart1S1,cutpart1S2,cutpart1S3,cutpart1S4] = compute4thCutValue(clusters,W,normalized,deg)
% Computes the three cut values of a 4-clustered matrix 
%
% Input:
%   clusters: a 4-clustered set; 
%   W: sparse  symmetric matrix;
%   normalized: Normalized case;
%   deg: converted sparse matrix obtained by summing along the columns
%        to full storage organization, is equal to is full(sum(W,2)).
%
% Output:
%   cutpart1S1: cut value of the first part;    
%   cutpart1S2: cut value of the second part;    
%   cutpart1S3: cut value of the third part; 
%   cutpart1S4: cut value of the third part; 
%
% This file is obtained by a modification of OneSpectralClustering.m,
% elaborated by M. Hein and T. B�hler 
% (Machine Learning Group, Saarland University, Germany, http://www.ml.uni-saarland.de)
% for the paper:
% An Inverse Power Method for Nonlinear Eigenproblems with Applications in 1-Spectral Clustering and Sparse PCA
% In Advances in Neural Information Processing Systems 23 (NIPS 2010)
%
% (C)2020-21 Antonio Corbo Esposito and Gianpaolo Piscitelli
% Dipartimento di Ingegneria Elettrica e dell'Informazione "M. Scarano",
% Via G. Di Biasio 43
% Universit� degli studi di Cassino e del Lazio Meridionale
% https://github.com/GianpaoloPiscitelli/One_Spectral_3_Clustering

n=size(W,1);
for i=1:n
    if (clusters(i)==1)
        S1(i)=1;
    else
        S1(i)=2;
    end
    if (clusters(i)==2)
        S2(i)=1;
    else
        S2(i)=2;
    end
    if (clusters(i)==3)
        S3(i)=1;
    else
        S3(i)=2;
    end
    if (clusters(i)==4)
        S4(i)=1;
    else
        S4(i)=2;
    end
    [cutpart1S1,cutpart2S1] = computeCutValue(S1,W,normalized,deg);
    [cutpart1S2,cutpart2S2] = computeCutValue(S2,W,normalized,deg);
    [cutpart1S3,cutpart2S3] = computeCutValue(S3,W,normalized,deg);
    [cutpart1S4,cutpart2S4] = computeCutValue(S4,W,normalized,deg);
end