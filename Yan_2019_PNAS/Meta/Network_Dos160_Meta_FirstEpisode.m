
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
%WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==1).*((DrugUseScore==1))==0) ))=0;

%WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==-1).*((DrugUseScore==1))==0) ))=0;
%WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==1)==0) ))=0;
%WantedSubMatrix(find( (Dx==1) .* (((DrugUseScore==-1))==0) ))=0;

WantedSubMatrix(find( (Dx==1) .* ((FirstEpisodeScore==-1)==0) ))=0; %%Recurrent

%Select subjects
WantedSubIndex = find(WantedSubMatrix);
SubID=SubID(WantedSubIndex);
Dx=Dx(WantedSubIndex);
Age=Age(WantedSubIndex);
Sex=Sex(WantedSubIndex);
Edu=Edu(WantedSubIndex);
Site=Site(WantedSubIndex);
Motion=Motion(WantedSubIndex,:);


WantedSubMatrix1789=WantedSubMatrix;
WantedSubMatrix1789Index=find(WantedSubMatrix1789);

%Exclude Site with N<10
SubjectNumberPerSite=[];
SiteIndex = unique(Site);
WantedSubMatrix=ones(length(SubID),1);
for i=1:length(SiteIndex)
    DxTemp=Dx(find((Site==SiteIndex(i)))); %DxTemp=Dx(find(Site==SiteIndex(i)));
    SubjectNumberPerSite(i,:)=[SiteIndex(i),length(find(DxTemp==1)),length(find(DxTemp==-1))];
    if (length(find(DxTemp==1))<10)||(length(find(DxTemp==-1))<10)
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

WantedSubMatrix1789Index=WantedSubMatrix1789Index(WantedSubIndex);

WantedSubMatrix1789=zeros(1789,1);
WantedSubMatrix1789(WantedSubMatrix1789Index)=1;


load /mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/NetworkAnalysis/zROICorr/ROISignals_FunImgARCWF/Dos160_ROICorrelation_FisherZ_Set.mat
ROICorrelation_FisherZ_Set=ROICorrelation_FisherZ_Set(:,:,find(WantedSubMatrix1789));




%Check for networks
load /mnt/Data/RfMRILab/Yan/YAN_Program/Atlas/Dos160_WithName.mat
Network=zeros(160,1);
for i=1:length(Dos160_WithName)
    switch Dos160_WithName{i,5}
        case 'occipital'
            Network(i)=1;
        case 'sensorimotor'
            Network(i)=2;
        case 'default'
            Network(i)=3;
        case 'fronto-parietal'
            Network(i)=4;
        case 'cingulo-opercular'
            Network(i)=5;
        case 'cerebellum'
            Network(i)=6;
    end
end

Network142=Network;
Network142(find(Network==6))=[];
Dos142_WithName=Dos160_WithName;
Dos142_WithName(find(Network==6),:)=[];

Network142_Yeo=Dos160_YeoNetwork_YanModified; %Network142_Yeo=Dos160_YeoNetwork;
Network142_Yeo(find(Network==6))=[];

Network142_Yeo(find(Network142_Yeo==10))=5; %Change subcortical to 5





ROICorrelation_FisherZ_Set(find(Network==6),:,:)=[];
ROICorrelation_FisherZ_Set(:,find(Network==6),:)=[];



%Average FC as between network
%For Yeo

MergeLabel = Network142_Yeo;
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






% Convert into 2D
YMatrix=reshape(NetworkCorrSet,[],size(NetworkCorrSet,3))';

SubIDAll=SubID;
DxAll=Dx;
AgeAll=Age;
SexAll=Sex;
EduAll=Edu;
MotionAll=Motion;

SiteIndex = unique(Site);

TMatrix=zeros(length(SiteIndex),size(YMatrix,2));
N1=zeros(length(SiteIndex),1);
N2=zeros(length(SiteIndex),1);
for i=1:length(SiteIndex)
    SubID=SubIDAll(find(Site==SiteIndex(i)));
    Dx=DxAll(find(Site==SiteIndex(i)));
    Age=AgeAll(find(Site==SiteIndex(i)));
    Sex=SexAll(find(Site==SiteIndex(i)));
    Edu=EduAll(find(Site==SiteIndex(i)));
    Motion=MotionAll(find(Site==SiteIndex(i)));
    AllCov = [ones(length(SubID),1), Dx,Age,Sex,Edu,Motion];
    %Centering: Let the first column (constant) have the mean effect.
    AllCov(:,2:end) = (AllCov(:,2:end)-repmat(mean(AllCov(:,2:end)),size(AllCov(:,2:end),1),1));
    Contrast=zeros(1,size(AllCov,2));
    Contrast(2)=1;

    for iY=1:size(YMatrix,2)
        y=squeeze(YMatrix(find(Site==SiteIndex(i)),iY));
        [b,r,SSE,SSR, T, TF_ForContrast] = y_regress_ss(y,AllCov,Contrast,'T');
        TMatrix(i,iY)=TF_ForContrast;
    end
    N1(i,1)=length(find(Dx==1));
    N2(i,1)=length(find(Dx==-1));
end

TVal=TMatrix;
nTests=size(YMatrix,2);
OutputName='/mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/Stats/Stats_MDD_848_794/Network/Edge/Meta/Temp/Temp';
[Path, fileN, extn] = fileparts(OutputName);
MatNameForR=fullfile(Path,[fileN,'_ForR.mat']);
save(MatNameForR,'TVal','N1','N2','nTests');
MatNameRResults=fullfile(Path,[fileN,'_RResults.mat']);

[ProgramPath] = fileparts(which('y_Meta_Image_CallR.m'));
Expression = sprintf('!Rscript %s%sR_Cal_Meta.R %s %s', ProgramPath, filesep,MatNameForR,MatNameRResults);
eval(Expression);
load(MatNameRResults);

ZMatrix=reshape(Z,[size(NetworkCorrSet,1) size(NetworkCorrSet,2)]);
PMatrix=reshape(P,[size(NetworkCorrSet,1) size(NetworkCorrSet,2)]);





%FDR
TriuMat = triu(ones(size(PMatrix)),0)';

PVector = PMatrix(find(TriuMat));

addpath /mnt/Data/RfMRILab/Yan/YAN_Program/gretna

[pID,pN] = FDR(PVector,0.05);

PSig = PMatrix<=pID;


% 
% 
% %FDR restricted in First level significant
% SignificantIndex=[1 1; 1 2; 1 3; 2 2; 2 3; 3 3; 7 7];
% Ind = sub2ind([7 7], SignificantIndex(:,1),SignificantIndex(:,2));
% PVector = PMatrix(Ind);
% [pID,pN] = FDR(PVector,0.05);
% PSig = PMatrix<=pID;
% 
% find(PVector<=pID)
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %FDR witin All Significant Edges
% All=load('/mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/Stats/Stats_MDD_848_794/Network/Edge/Edge_LME.mat');
% load /mnt/Data/RfMRILab/Yan/YAN_Work/REST-meta-MDD/Processing/Stats/Stats_MDD_848_794/Network/Edge/Edge_LME_FirstEpisodeDrugNaive.mat
% 
% TriuMat = triu(ones(size(PMatrix)),1)';
% TriuMat=TriuMat.*(All.PMatrix<=All.pID);
% PVector = PMatrix(find(TriuMat));
% [pID,pN] = FDR(PVector,0.05);
% 
% 
% %Restore to symetric
% TMatrix=TMatrix+TMatrix';
% PMatrix(find(All.PMatrix>All.pID))=1;%Remove those unsignificant
% TriuMat = triu(ones(size(PMatrix)),1);
% PMatrix(find(TriuMat))=0;
% PMatrix=PMatrix+PMatrix';
% PMatrix(find(eye(size(PMatrix))))=1;
% 
% 
% 
% 
% 
% load /mnt/Data/RfMRILab/Yan/YAN_Program/Atlas/Dos160_WithName.mat
% Network=zeros(160,1);
% for i=1:length(Dos160_WithName)
%     switch Dos160_WithName{i,5}
%         case 'occipital'
%             Network(i)=1;
%         case 'sensorimotor'
%             Network(i)=2;
%         case 'default'
%             Network(i)=3;
%         case 'fronto-parietal'
%             Network(i)=4;
%         case 'cingulo-opercular'
%             Network(i)=5;
%         case 'cerebellum'
%             Network(i)=6;
%     end
% end
% 
% Network142=Network;
% Network142(find(Network==6))=[];
% Dos142_WithName=Dos160_WithName;
% Dos142_WithName(find(Network==6),:)=[];
% 
% Network142_Yeo=Dos160_YeoNetwork_YanModified; %Network142_Yeo=Dos160_YeoNetwork;
% Network142_Yeo(find(Network==6))=[];
% 
% Network142_Yeo(find(Network142_Yeo==10))=5; %Change subcortical to 5
% 
% 
% 
% MergeLabel = Network142_Yeo;
% 
% PSurviveP = (PMatrix<=pID).*(TMatrix>0);
% PSurviveN = (PMatrix<=pID).*(TMatrix<0);
% 
% PSurviveCount=PSurviveP;
% 
% LabelIndex = unique(MergeLabel);
% CountSet = zeros(length(LabelIndex),length(LabelIndex));
% CountSet_Full = zeros(length(LabelIndex),length(LabelIndex));
% FullMatrix=ones(size(PSurviveCount))-eye(size(PSurviveCount));
% for j=1:length(LabelIndex)
%     for k=1:length(LabelIndex)
%         A=double(MergeLabel==LabelIndex(j));
%         B=double(MergeLabel==LabelIndex(k));
%         Matrix = A*B';
%         MatrixIndex = find(Matrix);
%         CountSet(j,k) = sum(PSurviveCount(MatrixIndex));
%         CountSet_Full(j,k) = sum(FullMatrix(MatrixIndex));
%     end
% end
% 
% CountSet=CountSet./(eye(size(CountSet))+ones(size(CountSet)));
% CountSet_Full=CountSet_Full./(eye(size(CountSet_Full))+ones(size(CountSet_Full)));
% CountSetPercent=CountSet./CountSet_Full;
% 
% 
% 
% %Get connection name
% Table=[];
% for j=1:length(LabelIndex)
%     for k=j:length(LabelIndex)
%         A=double(MergeLabel==LabelIndex(j));
%         B=double(MergeLabel==LabelIndex(k));
%         Matrix = A*B';
%         
%         PSurviveCountMatrix = PSurviveCount.*Matrix;
%         PSurviveCountMatrixIndex = find(PSurviveCountMatrix);
% 
%         for iInd=1:length(PSurviveCountMatrixIndex)
%             [II,JJ] = ind2sub(size(PSurviveCount),PSurviveCountMatrixIndex(iInd));
%             if ~(j==k && JJ>=II)
%                 Row={TMatrix(II,JJ),j,k,II,JJ,Dos142_WithName{II,4},Dos142_WithName{JJ,4}};
%                 Table=[Table;Row]
%             end
%         end
%     end
% end
% 
% 
% 



