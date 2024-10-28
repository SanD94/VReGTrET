%% -------------------step3_interpolateLostData_WB.m-----------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description: 
% Third script to run in pre-processing pipeline
% applies the interpolation of lost data samples (noData) if the
% interpolation conditions apply: interpolation of clusters only iff: 
% noData clusters are < 266 ms long and occur between the same collider

% Input: 
% condensedColliders_3Sessions_V3.mat = the condesedColliders file after
%                                       combining all 3 session in the
%                                       script
%                                       "step2_optional_join3SessionsVR_V3"
% Output: 
% interpolatedColliders_3Sessions_V3.mat = the newly interpolated data file

% Missing_Participant_Files.mat = contains all participant numbers where the
%                                  data file could not be loaded


clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

cd 'F:\big-data\vr_data\Data\preprocessing-pipeline\interpolated-colliders'

PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020, 2025};


% --------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;

checkInterpolation = [];


for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    
    file = strcat(num2str(currentPart),'_interpolatedColliders_5Sessions_WB.mat');
    json_file = strcat(num2str(currentPart),'_interpolatedColliders_5Sessions_WB.json');
 
    % check for missing files
    if exist(file)==0
        countMissingPart = countMissingPart+1;
        
        noFilePartList = [noFilePartList;currentPart];
        disp(strcat(file,' does not exist in folder'));
    %% main code   
    elseif exist(file)==2
        tic
        % load data
        interpolatedColliders = load(file);
        interpolatedColliders = interpolatedColliders.interpolatedData;
        json_interpolated_collider = jsonencode(interpolatedColliders);
        fid = fopen(json_file, "w");
        fprintf(fid, "%s", json_interpolated_collider);
        fclose(fid);
        
    else
        disp('something went really wrong with participant list');
    end

end

disp(strcat(num2str(Number), ' Participants format changed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(strcat(savepath,'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');

disp('done');