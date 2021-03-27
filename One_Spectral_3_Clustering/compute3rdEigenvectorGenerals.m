function [fold,FctValOuter]=compute3rdEigenvectorGenerals(W,eigv,fold,normalized,verbose,deg)
% Computes second nonconstant eigenvector of the 1-Laplacian using the 
% nonlinear inverse power method.
%
% Input:
%   W: Sparse symmetric weight matrix.
%   eigv: nonconstant eigenvector of 1-Laplacian computed by computeEigenvectorGeneral
%   fold: Start vector. Use multiple runs with random initialization.
%   normalized: True/false for normalized/unnormalized 1-spectral clustering.
%   (Optional:) deg: Degrees of vertices as column vector. Default
%   is full(sum(W,2)) in normalized case and ones(size(W,1),1) in 
%   unnormalized case. Will be ignored if normalized=false.
%
% Output:
%	fold: Final eigenvector.
%   FctValOuter: Values of the functional in each iteration.
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

n=size(W);
    if(nargin<5)
        verbose=true;
    end
    if nargin<6
        if (normalized)
			deg=full(sum(W,2));
		else
			deg=ones(size(W,1),1);
        end
    else
       deg=full(deg); 
    end
    
    
    assert(isnumeric(W) && issparse(W),'Wrong usage. W should be sparse and numeric.');

	[ix,jx,wval]=find(W);
	W2=triu(W);
	MaxSumSquaredWeights=2*max(sum(W.^2));

	pars.MAXITER=40;
	pars.epsilon = 1E-14; 
	%pars.tv = 'l1';
	maxiterations = 100;
    %normL1=Inf;
    Iprec=-Inf;
    I=0;
    G=0;
    for i=1:n
        G=G+(abs(fold(i))*deg(i));
        for j=1:n
                I=I+W(i,j)*abs(fold(i)-fold(j));
        end
    end
    I=I/G;

    %while (sum(abs(fold))<normL1) 
    while (I>Iprec) 
        % Subtract median
        if (~normalized)
            fold = fold - median(fold);
            %fold = PseudoProd(W,fold,eigv,deg);
            fold = PseudoOrt(W,fold,eigv,deg);
        else
            fold = fold - weighted_median(fold,deg);
            %fold = PseudoProd(W,fold,eigv,deg);
            fold = PseudoOrt(W,fold,eigv,deg);
        end
        Iprec=I;
        I=0;
        G=0;
        for i=1:n
            for j=1:n
                I=I+W(i,j)*abs(fold(i)-fold(j));
            end
        end
        %normL1=sum(abs(fold));
        I=I/G;
    end
    
	counter=0;
	diffFunction=inf; 
    rvalold=zeros(length(ix),1); 
	FctValOld=inf;
	FctValOuter=[]; 
    fnew=fold; 

	while(counter<maxiterations)
		% compute current functional value
		sval = wval.*abs(fnew(ix)-fnew(jx));
		if (~normalized)
			FctVal = 0.5*sum(sval)/norm(fnew,1);
		else
			FctVal = 0.5*sum(sval)/(deg'*abs(fnew));
		end
	  
		% if functional value has not yet decreased, increase maximum number of
		% inner iterations
		if(FctVal>=FctValOld)
            if(verbose)
                disp(['Functional has not decreased. Old: ',num2str(FctValOld,'%1.16f'),' - New: ',num2str(FctVal,'%1.16f'),'. Increasing number of inner iterations.']); 
            end
            pars.MAXITER=pars.MAXITER*2;
        	if(pars.MAXITER>800) break; end
			fold=foldback; 
			FctOld=FctValOld;
			FctVal=FctValOld;
		else
			fold = fnew;
			FctValOuter=[FctValOuter,FctVal];
			foldback=fold;
			FctOld=FctValOld;
			FctValOld = FctVal;
        end
        
        if(verbose)
            [ac,cut,cheeger]=createClustersGeneral(fold,W,normalized,-1,2,deg);
            disp(['****Iter: ',num2str(counter),' - Functional: ',num2str(FctVal,'%1.16f'),'- CheegerBest: ',num2str(cheeger,'%1.14f'),' - DiffF: ',num2str(diffFunction,'%1.14f')]);
            disp([' ']);
        end
	  
		% make sure we have <vec,1>=0
		if (~normalized)
		  ixNull=find(fold==0); %ixNull=ixNull(randperm(length(ixNull)));
		  Pos=sum(fold>0);
		  Neg=sum(fold<0);
		  Null=length(ixNull);
		  fcur=sign(fold);
		  if(Null>0)
			diffPosNeg=Pos-Neg;
			fcur(ixNull)=-diffPosNeg/length(ixNull);
		  end
		  vec = fcur;
		else
		  ixNull=find(fold==0); %ixNull=ixNull(randperm(length(ixNull)));
		  ixPos=find(fold>0);
		  ixNeg=find(fold<0);
		  Pos=sum(deg(ixPos));
		  Neg=sum(deg(ixNeg));
		  Null=sum(deg(ixNull));
		  fcur=deg.*sign(fold);
		  if(Null>0)
            diffPosNeg=Pos-Neg;
			fcur(ixNull)= -deg(ixNull)* diffPosNeg/Null;
		  end
		  vec = fcur;
		end
	  
		% Solve inner problem
		[fnew,rvalold,Obj,niter]=solveInnerProblem(W2,FctVal*full(vec),FctVal/FctOld*rvalold,pars.MAXITER,pars.epsilon,MaxSumSquaredWeights); % 
        
        if (Obj==0) 
            fnew=fold;
            counter=maxiterations;
        end
        if(verbose)
            if(normalized)
                disp(['Sum of signs: ',num2str(sum(vec)),' - Median: ',num2str(weighted_median(fnew,deg)),' - Mean: ',num2str(deg'*fnew/sum(deg))]);
            else
                disp(['Sum of signs: ',num2str(sum(vec)),' - Median: ',num2str(median(fnew)),' - Mean: ',num2str(mean(fnew))]);
            end
        end
		
        if(verbose)
            disp(['-- Inner Prob - Final Obj: ',num2str(Obj,'%1.16f'),' - Number of Iterations: ',num2str(niter)]);
            f3=fnew/norm(fnew); 
            sval3 = wval.*abs(f3(ix)-f3(jx)); 
            Obj2=0.5*sum(sval3)-FctVal*vec'*f3;
            disp(['-- Original Obj: ',num2str(Obj2,'%1.16f'),' - Zeros: ',num2str(sum(fold==0)),' - Balance: ',num2str(sum(sign(fold)))]);
        end
        
        %normL1=Inf;
        Iprec=-Inf;
        I=0;
        G=0;
        for i=1:n
            for j=1:n
                I=I+W(i,j)*abs(fold(i)-fold(j));
            end
        end
        I=I/G;
        
        %while (sum(abs(fnew))<normL1)
        while (I>Iprec)
            % Subtract median
            if (~normalized)
                fnew = fnew - median(fnew);
                fnew = PseudoProd(W,fnew,eigv,deg);
                %fnew = PseudoOrt(W,fnew,eigv,deg);
            else
                fnew = fnew - weighted_median(fnew,deg);
                fnew = PseudoProd(W,fnew,eigv,deg);
                %fnew = PseudoOrt(W,fnew,eigv,deg);
            end
            %normL1=sum(abs(fnew));
            Iprec=I;
            I=0;
            G=0;
            for i=1:n
                for j=1:n
                    I=I+W(i,j)*abs(fold(i)-fold(j));
                end
            end
            I=I/G;
        end              
        fnew = fnew/norm(fnew,1);
	 
		diffFunction = min(norm(fnew-fold),norm(fnew+fold));
		counter=counter+1;
	end


	% compute most recent Functional value
	sval = wval.*abs(fnew(ix)-fnew(jx));
    if(~normalized)
        FctVal = 0.5*sum(sval)/norm(fnew,1);
	else
		FctVal = 0.5*sum(sval)/(deg'*abs(fnew));
    end
    
    if(FctVal<FctValOld)
        fold = fnew;
        FctValOuter=[FctValOuter,FctVal];
    else
        FctVal=FctValOld;
    end
    if(verbose)
        [ac,cut,cheeger]=createClustersGeneral(fold,W,normalized,-1,2,deg);
        disp(['Functional: ',num2str(FctVal,'%1.16f'),' - Cheeger: ',num2str(cheeger,'%1.14f')]);
    end
end