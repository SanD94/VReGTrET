%% -----------------------step4_gazes_vs_noise_WB.m------------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description:
% Fourth step in the preprocessing pipeline.
% Script divides the interpolated Collider data based on the gaze threshold 
% into gazes and noisy samples (excluded data), i.e. it identifies the gaze events


% Input: 
% interpolatedColliders_3Sessions_V3.mat = the interpolated data file

% Output: 
% gazes_data_V3.mat = a new data file containing all gazes

% noisy_data_V3.mat = all excluded data

% Overview_Gazes.mat = overview of the amount of gazes and excluded data 
%                      for each participant
        
% Missing_Participant_Files.mat = contains all participant numbers where the
%                                  data file could not be loaded

clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

savepath = '../noises-vs-gazes/';

cd '../Data/preprocessing-pipeline/interpolated-colliders/';

% 20 participants with 90 min VR trainging less than 30% data loss
PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020};

%----------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;
countAnalysedPart= 0;

overviewGazes = array2table(zeros(Number,4));
overviewGazes.Properties.VariableNames = {'Participant','totalAmount','gazes','noise'};


for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    
    file = strcat(num2str(currentPart),'_interpolatedColliders_5Sessions_WB.mat');
 
    % check for missing files
    if exist(file)==0
        countMissingPart = countMissingPart+1;
        
        noFilePartList = [noFilePartList;currentPart];
        disp(strcat(file,' does not exist in folder'));
    %% main code   
    elseif exist(file)==2
        tic
        countAnalysedPart = countAnalysedPart +1;
        % load data
        interpolatedData = load(file);
        interpolatedData = interpolatedData.interpolatedData;
        
        % threshold based classification of gazes
        % a gaze is a cluster of min duration of 266.6 ms
        

        gazes = [interpolatedData.clusterDuration] > 266.6;
        
        

        
        gazes_data = interpolatedData(gazes);
        
        noisy_data = interpolatedData(not(gazes));
              
        
        
        % save both tables
        save([savepath num2str(currentPart) '_gazes_data_WB.mat'],'gazes_data');
        save([savepath num2str(currentPart) '_noisy_data_WB.mat'],'noisy_data');
        
        % update overview with values
        
        overviewGazes.Participant(countAnalysedPart)= currentPart;
        overviewGazes.totalAmount(countAnalysedPart)= length(interpolatedData);
        overviewGazes.gazes(countAnalysedPart)= length(gazes_data);
        overviewGazes.noise(countAnalysedPart) = length(noisy_data);
        
     
  
        toc
        
    else
        disp('something went really wrong with participant list');
    end

end
disp(strcat(num2str(Number), ' Participants in List'));
disp(strcat(num2str(countAnalysedPart), ' Participants analyzed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(strcat(savepath,'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');

save([savepath 'Overview_Gazes.mat'],'overviewGazes');
disp('saved Overview Gazes');

disp('done');