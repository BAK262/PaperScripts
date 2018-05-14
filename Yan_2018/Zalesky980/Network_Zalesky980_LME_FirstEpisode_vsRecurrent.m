
clear all;clc

addpath(fullfile(matlabroot,'toolbox','stats','stats'))

%Select subjects
load /mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/Stats/Stats_MDD_943_846/DataQC/CorrSet.mat
load /mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/SubInfo/Info_Final1789_943_846.mat

ReHoGood = (CorrSet_All(:,3) >= 0.6); %Exclude ReHo Correlation < 0.6

%Exclude Site with N<10
SubjectNumberPerSite=[];
SiteIndex = unique(Site);
WantedSubMatrix=ones(length(SubID),1);
for i=1:length(SiteIndex)
    DxTemp=Dx(find((Site==SiteIndex(i)).*ReHoGood)); %DxTemp=Dx(find(Site==SiteIndex(i)));
    SubjectNumberPerSite(i,:)=[SiteIndex(i),length(find(DxTemp==1)),length(find(DxTemp==-1))];
    if (length(find(DxTemp==1))<10)||(length(find(DxTemp==-1))<10)
        WantedSubMatrix(find(Site==SiteIndex(i)))=0;
    end
end

WantedSubMatrix = WantedSubMatrix.*ReHoGood;

load /mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/SubInfo/FirstEpisodeDrugNaive.mat
%Get the correponding FEDN scroe
FirstEpisodeScore=zeros(length(SubID),1);
DrugUseScore=zeros(length(SubID),1);
for i=1:length(SubID)
    for j=1:size(FEDNTalbe,1)
        if strcmpi(SubID{i},FEDNTalbe{j,1})
            FirstEpisodeScore(i)=FirstEpisode(j);
            DrugUseScore(i)=DrugUse(j);
        end
    end
end

%WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==1).*((DrugUseScore==-1))==0) ))=0;

%WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==-1).*((DrugUseScore==1))==0) ))=0;
%WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==-1)==0) ))=0;
%WantedSubMatrix(find( (Dx==1) .* (((DrugUseScore==1))==0) ))=0;

%WantedSubMatrix(find( ((FirstEpisodeScore==-1)+(FirstEpisodeScore==1)) ==0 )) = 0;
WantedSubMatrix(find( ((FirstEpisodeScore==1).*((DrugUseScore==-1))+(FirstEpisodeScore==-1)) ==0 )) = 0;


%Select subjects
WantedSubIndex = find(WantedSubMatrix);
SubID=SubID(WantedSubIndex);
Dx=Dx(WantedSubIndex);
Age=Age(WantedSubIndex);
Sex=Sex(WantedSubIndex);
Edu=Edu(WantedSubIndex);
Site=Site(WantedSubIndex);
Motion=Motion(WantedSubIndex,:);
FirstEpisodeScore=FirstEpisodeScore(WantedSubIndex);


DataDir='/mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Raw/REST-meta-MDD-Organized/Results/ROISignals_FunImgARCWF';
%Bonds=[1 116; 117 212; 213 228; 229 428; 429 1408; 1409 1568; 1570 1833];
Bonds=[429 1408];
j=1;
ROICorrelation_FisherZ_Set=zeros(Bonds(j,2)-Bonds(j,1)+1,Bonds(j,2)-Bonds(j,1)+1,length(SubID));
for i=1:length(SubID)
    ROISignals=load([DataDir,'/','ROISignals_',SubID{i},'.mat']);
    Sig=ROISignals.ROISignals(:,Bonds(j,1):Bonds(j,2));
    ROICorrelation = corrcoef(Sig);
    ROICorrelation_FisherZ = 0.5 * log((1 + ROICorrelation)./(1- ROICorrelation));
    ROICorrelation_FisherZ(find(eye(size(ROICorrelation_FisherZ))))=0;
    ROICorrelation_FisherZ_Set(:,:,i)=ROICorrelation_FisherZ;
end



load /mnt/Data/RfMRILab/Yan/YAN_Program/Atlas/Zalesky980_YeoNetwork.mat
Temp=load('/mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/Stats/Stats_MDD_848_794/ROIAnalysis/sgACC_Zalesky/FCMatrix/TMatrix_All.mat');
ROI_Remove=Temp.NaNROI(1:end-1); %We still need the 120th ROI
ROIWanted=1:980;
ROIWanted(ROI_Remove)=[];
YeoNetwork(ROI_Remove)=[];
ROIWanted(find(YeoNetwork==0))=[];
YeoNetwork(find(YeoNetwork==0))=[];

ROICorrelation_FisherZ_Set=ROICorrelation_FisherZ_Set(ROIWanted,ROIWanted,:);






%Exclude Site with N<10
SubjectNumberPerSite=[];
SiteIndex = unique(Site);
WantedSubMatrix=ones(length(SubID),1);
for i=1:length(SiteIndex)
    FirstEpisodeScoreTemp=FirstEpisodeScore(find((Site==SiteIndex(i)))); %DxTemp=Dx(find(Site==SiteIndex(i)));
    SubjectNumberPerSite(i,:)=[SiteIndex(i),length(find(FirstEpisodeScoreTemp==1)),length(find(FirstEpisodeScoreTemp==-1))];
    if (length(find(FirstEpisodeScoreTemp==1))<10)||(length(find(FirstEpisodeScoreTemp==-1))<10)
        WantedSubMatrix(find(Site==SiteIndex(i)))=0;
    end
end

%Select subjects
WantedSubIndex = find(WantedSubMatrix);
SubID=SubID(WantedSubIndex);
Dx=Dx(WantedSubIndex);
Age=Age(WantedSubIndex);
Sex=Sex(WantedSubIndex);
Edu=Edu(WantedSubIndex);
Site=Site(WantedSubIndex);
Motion=Motion(WantedSubIndex,:);
FirstEpisodeScore=FirstEpisodeScore(WantedSubIndex);

ROICorrelation_FisherZ_Set=ROICorrelation_FisherZ_Set(:,:,WantedSubIndex);






X=[ones(size(FirstEpisodeScore)),FirstEpisodeScore,Age,Sex,Edu,Motion];
Z={ones(size(FirstEpisodeScore)),FirstEpisodeScore};
G={Site,Site};


%Average FC as between network
%For Yeo

MergeLabel = YeoNetwork;
LabelIndex = unique(MergeLabel);
NetworkCorr = zeros(length(LabelIndex),length(LabelIndex));
NetworkCorrSet = zeros(length(LabelIndex),length(LabelIndex),size(ROICorrelation_FisherZ_Set,3));
FullMatrix=ones(size(ROICorrelation_FisherZ_Set,1),size(ROICorrelation_FisherZ_Set,2))-eye(size(ROICorrelation_FisherZ_Set,1),size(ROICorrelation_FisherZ_Set,2));

for iSub=1:size(ROICorrelation_FisherZ_Set,3)
    CountSet_Full = zeros(length(LabelIndex),length(LabelIndex));
    for j=1:length(LabelIndex)
        for k=1:length(LabelIndex)
            A=double(MergeLabel==LabelIndex(j));
            B=double(MergeLabel==LabelIndex(k));
            Matrix = A*B';
            MatrixIndex = find(Matrix);
            CorrZ = ROICorrelation_FisherZ_Set(:,:,iSub);
            NetworkCorr(j,k) = sum(CorrZ(MatrixIndex));
            CountSet_Full(j,k) = sum(FullMatrix(MatrixIndex));
        end
    end
    NetworkCorr=NetworkCorr./CountSet_Full;
    NetworkCorrSet(:,:,iSub)=NetworkCorr;
end




%For Average FC
TMatrix = zeros(size(NetworkCorrSet,2),size(NetworkCorrSet,2));
PMatrix = ones(size(NetworkCorrSet,2),size(NetworkCorrSet,2));
for ii=1:size(NetworkCorrSet,2)
    for jj=1:size(NetworkCorrSet,2)
        y=squeeze(NetworkCorrSet(ii,jj,:));
        lme = fitlmematrix(X,y,Z,G);
        TMatrix(ii,jj)=lme.Coefficients{2,4}; %
        PMatrix(ii,jj)=lme.Coefficients{2,6};
    end
    fprintf('%d\n',ii)
end


%FDR
TriuMat = triu(ones(size(PMatrix)),0)';

PVector = PMatrix(find(TriuMat));

addpath /mnt/Data/RfMRILab/Yan/YAN_Program/gretna

[pID,pN] = FDR(PVector,0.05);

PSig = PMatrix<=pID;

% 
% %FDR restricted in First level significant
% SignificantIndex=[1 1; 1 2; 1 3; 2 2; 2 3; 7 7];
% Ind = sub2ind([7 7], SignificantIndex(:,1),SignificantIndex(:,2));
% PVector = PMatrix(Ind);
% [pID,pN] = FDR(PVector,0.05);
% PSig = PMatrix<=pID;
% 
% 






% 
% 
% 
% 
% 
% 
% %Test if site random effect significant
% X=[ones(size(FirstEpisodeScore)),FirstEpisodeScore,Age,Sex,Edu,Motion];
% ZReduced={ones(size(FirstEpisodeScore))};
% GReduced={Site};
% 
% TMatrix = zeros(size(NetworkCorrSet,2),size(NetworkCorrSet,2));
% PMatrix = ones(size(NetworkCorrSet,2),size(NetworkCorrSet,2));
% for ii=1:size(NetworkCorrSet,2)
%     for jj=1:size(NetworkCorrSet,2)
%         y=squeeze(NetworkCorrSet(ii,jj,:));
%         lme = fitlmematrix(X,y,Z,G);
%         lme_Reduced = fitlmematrix(X,y,ZReduced,GReduced);
%         ModelCompare=compare(lme_Reduced,lme);
%         PMatrix(ii,jj)=ModelCompare.pValue(2);
%     end
%     fprintf('%d\n',ii)
% end
% 
% 
% 
% 
% 
% 
% %Check Site Effect
% 
% SubIDAll=SubID;
% DxAll=Dx;
% AgeAll=Age;
% SexAll=Sex;
% EduAll=Edu;
% MotionAll=Motion;
% FirstEpisodeScoreAll=FirstEpisodeScore;
% 
% SiteIndex = unique(Site);
% TMatrix = zeros(size(NetworkCorrSet,2),size(NetworkCorrSet,2),length(SiteIndex));
% PMatrix = ones(size(NetworkCorrSet,2),size(NetworkCorrSet,2),length(SiteIndex));
% for i=1:length(SiteIndex)
%     
%     SubID=SubIDAll(find(Site==SiteIndex(i)));
%     Dx=DxAll(find(Site==SiteIndex(i)));
%     Age=AgeAll(find(Site==SiteIndex(i)));
%     Sex=SexAll(find(Site==SiteIndex(i)));
%     Edu=EduAll(find(Site==SiteIndex(i)));
%     Motion=MotionAll(find(Site==SiteIndex(i)));
%     
%     FirstEpisodeScore=FirstEpisodeScoreAll(find(Site==SiteIndex(i)));
%     AllCov = [ones(length(SubID),1), FirstEpisodeScore,Age,Sex,Edu,Motion];
%     
%     
%     %Centering: Let the first column (constant) have the mean effect.
%     AllCov(:,2:end) = (AllCov(:,2:end)-repmat(mean(AllCov(:,2:end)),size(AllCov(:,2:end),1),1));
%     
%     Contrast=zeros(1,size(AllCov,2));
%     Contrast(2)=1;
%     
%     for ii=1:size(NetworkCorrSet,2)
%         for jj=1:size(NetworkCorrSet,2)
%             y=squeeze(NetworkCorrSet(ii,jj,find(Site==SiteIndex(i))));
%             [b,r,SSE,SSR, T, TF_ForContrast, Cohen_f2] = y_regress_ss(y,AllCov,Contrast,'T');
%             
%             TMatrix(ii,jj,i)= T(2); %
%             PMatrix(ii,jj,i)=2*(1-tcdf(abs(T(2)), size(AllCov,1)-size(AllCov,2)));
%         end
%         fprintf('%d\n',ii)
%     end
%     
% end
% 


