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

savepath = '../interpolated-colliders/';

cd '../Data/preprocessing-pipeline/condensed-colliders-combined/'

PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020};


% --------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;

checkInterpolation = [];


for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    
    file = strcat(num2str(currentPart),'_condensedColliders5S_WB.mat');
 
    % check for missing files
    if exist(file)==0
        countMissingPart = countMissingPart+1;
        
        noFilePartList = [noFilePartList;currentPart];
        disp(strcat(file,' does not exist in folder'));
    %% main code   
    elseif exist(file)==2
        tic
        % load data
        condensedColliders = load(file);
        condensedColliders = condensedColliders.condensedColliders5S;
        rawSave = condensedColliders;
        
        interpolatedData = condensedColliders;
      
        
        firstSum = sum([condensedColliders.sampleNr]);
        firstSumCHeck = sum([interpolatedData.sampleNr]);
        removeRows = false(length(condensedColliders),1);
        testi = zeros(length(condensedColliders),1);
        problem = 0;
        rowTest = 0;
        exceptions = 0;

        % go through all rows
        for index = 1:length(condensedColliders)

            % if the row is a noData row
            if strcmp(condensedColliders(index).hitObjectColliderName,'noData')
  
%                 clusterDur = condensedColliders(index).clusterDuration;
                
            % if number of missing samples if small enough, they get
            % interpolated
            if (condensedColliders(index).clusterDuration < 250)
                
%                 ibefore = index -1;
%                 iafter = index+1;

                % catch exceptions
                if index ==1 % if it is the first row - no interpolation
                    exceptions = exceptions +1;
                    
                elseif index == length(condensedColliders) % if it is the last row, no interpolation
                    exceptions = exceptions +1;
                    
              
                %% differentiating if seen houses before and after missing
                % if colliders are identical
                elseif strcmp(condensedColliders(index-1).hitObjectColliderName,condensedColliders(index+1).hitObjectColliderName)
                    
                    % and if the line before was not already marked for removal
                    if (removeRows(index-1) == false)
                        % combine all samples falling on the same house into
                        % one row
                        % note that clusters between sessions cant be
                        % interpolated, therefore the session variable does
                        % not need to be updated in case of interpolation

%                         
%%
                        % update cluster information
                        interpolatedData(index-1).sampleNr = sum([interpolatedData(index-1:index+1).sampleNr]);
                        interpolatedData(index-1).clusterDuration = sum([interpolatedData(index-1:index+1).clusterDuration]);
                        
                        % update rest of data
                        
                        % timestamps
                        interpolatedData(index-1).timeStampDataPointStart = [interpolatedData(index-1:index+1).timeStampDataPointStart];                    
                        interpolatedData(index-1).timeStampDataPointEnd  = [interpolatedData(index-1:index+1).timeStampDataPointEnd];
                        interpolatedData(index-1).timeStampGetVerboseData  = [interpolatedData(index-1:index+1).timeStampGetVerboseData];

                        % raycast information
                        interpolatedData(index-1).hitPointOnObject_x  = [interpolatedData(index-1:index+1).hitPointOnObject_x];
                        interpolatedData(index-1).hitPointOnObject_y  = [interpolatedData(index-1:index+1).hitPointOnObject_y];
                        interpolatedData(index-1).hitPointOnObject_z  = [interpolatedData(index-1:index+1).hitPointOnObject_z] ;

                        interpolatedData(index-1).hitObjectColliderBoundsCenter_x = [interpolatedData(index-1:index+1).hitObjectColliderBoundsCenter_x];
                        interpolatedData(index-1).hitObjectColliderBoundsCenter_y = [interpolatedData(index-1:index+1).hitObjectColliderBoundsCenter_y];
                        interpolatedData(index-1).hitObjectColliderBoundsCenter_z = [interpolatedData(index-1:index+1).hitObjectColliderBoundsCenter_z];

                        interpolatedData(index-1).hitObjectColliderisGraffiti  = [interpolatedData(index-1:index+1).hitObjectColliderisGraffiti];

                        % hdm information
                        interpolatedData(index-1).hmdPosition_x  = [interpolatedData(index-1:index+1).hmdPosition_x] ;
                        interpolatedData(index-1).hmdPosition_y  = [interpolatedData(index-1:index+1).hmdPosition_y] ;
                        interpolatedData(index-1).hmdPosition_z  = [interpolatedData(index-1:index+1).hmdPosition_z] ;

                        interpolatedData(index-1).hmdDirectionForward_x  = [interpolatedData(index-1:index+1).hmdDirectionForward_x ];
                        interpolatedData(index-1).hmdDirectionForward_y  = [interpolatedData(index-1:index+1).hmdDirectionForward_y ];
                        interpolatedData(index-1).hmdDirectionForward_z  = [interpolatedData(index-1:index+1).hmdDirectionForward_z ];

                        interpolatedData(index-1).hmdRotation_x  = [interpolatedData(index-1:index+1).hmdRotation_x ];
                        interpolatedData(index-1).hmdRotation_y  = [interpolatedData(index-1:index+1).hmdRotation_y];
                        interpolatedData(index-1).hmdRotation_z  = [interpolatedData(index-1:index+1).hmdRotation_z];

                        % body and player information
                        interpolatedData(index-1).playerBodyPosition_x  = [interpolatedData(index-1:index+1).playerBodyPosition_x];
                        interpolatedData(index-1).playerBodyPosition_y  = [interpolatedData(index-1:index+1).playerBodyPosition_y];
                        interpolatedData(index-1).playerBodyPosition_z  = [interpolatedData(index-1:index+1).playerBodyPosition_z];

                        interpolatedData(index-1).bodyTrackerPosition_x  = [interpolatedData(index-1:index+1).bodyTrackerPosition_x];
                        interpolatedData(index-1).bodyTrackerPosition_y  = [interpolatedData(index-1:index+1).bodyTrackerPosition_y];
                        interpolatedData(index-1).bodyTrackerPosition_z  = [interpolatedData(index-1:index+1).bodyTrackerPosition_z];

                        interpolatedData(index-1).bodyTrackerRotation_x  = [interpolatedData(index-1:index+1).bodyTrackerRotation_x];
                        interpolatedData(index-1).bodyTrackerRotation_y  = [interpolatedData(index-1:index+1).bodyTrackerRotation_y];
                        interpolatedData(index-1).bodyTrackerRotation_z  = [interpolatedData(index-1:index+1).bodyTrackerRotation_z];

                        % eye information
                        interpolatedData(index-1).eyeOpennessLeft  = [interpolatedData(index-1:index+1).eyeOpennessLeft] ;
                        interpolatedData(index-1).eyeOpennessRight  = [interpolatedData(index-1:index+1).eyeOpennessRight] ;

                        interpolatedData(index-1).pupilDiameterMillimetersLeft = [interpolatedData(index-1:index+1).pupilDiameterMillimetersLeft];
                        interpolatedData(index-1).pupilDiameterMillimetersRight = [interpolatedData(index-1:index+1).pupilDiameterMillimetersRight];

                        interpolatedData(index-1).eyePositionCombinedWorld_x  = [interpolatedData(index-1:index+1).eyePositionCombinedWorld_x] ;
                        interpolatedData(index-1).eyePositionCombinedWorld_y  = [interpolatedData(index-1:index+1).eyePositionCombinedWorld_y];
                        interpolatedData(index-1).eyePositionCombinedWorld_z  = [interpolatedData(index-1:index+1).eyePositionCombinedWorld_z];

                        interpolatedData(index-1).eyeDirectionCombinedWorld_x  = [interpolatedData(index-1:index+1).eyeDirectionCombinedWorld_x];
                        interpolatedData(index-1).eyeDirectionCombinedWorld_y  = [interpolatedData(index-1:index+1).eyeDirectionCombinedWorld_y];
                        interpolatedData(index-1).eyeDirectionCombinedWorld_z  = [interpolatedData(index-1:index+1).eyeDirectionCombinedWorld_z];

                        interpolatedData(index-1).eyeDirectionCombinedLocal_x  = [interpolatedData(index-1:index+1).eyeDirectionCombinedLocal_x];
                        interpolatedData(index-1).eyeDirectionCombinedLocal_y  = [interpolatedData(index-1:index+1).eyeDirectionCombinedLocal_y];
                        interpolatedData(index-1).eyeDirectionCombinedLocal_z  = [interpolatedData(index-1:index+1).eyeDirectionCombinedLocal_z];


         
                        
                        
                    elseif (removeRows(index-1) == true)
                        % if row before was already marked for removal
                        % backtracking to find last unmarked house
                        rowTest = index-1;

                        while removeRows(rowTest)

                            
                            rowTest = rowTest -1;

                            if rowTest < 1
                                break
                            end

                        end
                        % then update the row that combines all of the
                        % interpolated data
                        
                        % note that clusters between sessions cant be
                        % interpolated, therefore the session variable does
                        % not need to be updated in case of interpolation

% 
%                         
%%
                        interpolatedData(rowTest).sampleNr = sum([interpolatedData(rowTest).sampleNr, interpolatedData(index:index+1).sampleNr]);
                        interpolatedData(rowTest).clusterDuration = sum([interpolatedData(rowTest).clusterDuration,interpolatedData(index:index+1).clusterDuration]);
                        
                        % update rest of data
                        
                        % timestamps
                        interpolatedData(rowTest).timeStampDataPointStart = [interpolatedData(rowTest).timeStampDataPointStart,interpolatedData(index:index+1).timeStampDataPointStart];
                        interpolatedData(rowTest).timeStampDataPointEnd  = [interpolatedData(rowTest).timeStampDataPointEnd,interpolatedData(index:index+1).timeStampDataPointEnd];
                        interpolatedData(rowTest).timeStampGetVerboseData  = [interpolatedData(rowTest).timeStampGetVerboseData ,interpolatedData(index:index+1).timeStampGetVerboseData];

                        % raycast information
                        interpolatedData(rowTest).hitPointOnObject_x  = [interpolatedData(rowTest).hitPointOnObject_x ,interpolatedData(index:index+1).hitPointOnObject_x];
                        interpolatedData(rowTest).hitPointOnObject_y  = [interpolatedData(rowTest).hitPointOnObject_y,interpolatedData(index:index+1).hitPointOnObject_y];
                        interpolatedData(rowTest).hitPointOnObject_z  = [interpolatedData(rowTest).hitPointOnObject_z,interpolatedData(index:index+1).hitPointOnObject_z] ;

                        interpolatedData(rowTest).hitObjectColliderBoundsCenter_x = [interpolatedData(rowTest).hitObjectColliderBoundsCenter_x,interpolatedData(index:index+1).hitObjectColliderBoundsCenter_x];
                        interpolatedData(rowTest).hitObjectColliderBoundsCenter_y = [interpolatedData(rowTest).hitObjectColliderBoundsCenter_y,interpolatedData(index:index+1).hitObjectColliderBoundsCenter_y];
                        interpolatedData(rowTest).hitObjectColliderBoundsCenter_z = [interpolatedData(rowTest).hitObjectColliderBoundsCenter_z,interpolatedData(index:index+1).hitObjectColliderBoundsCenter_z];

                        interpolatedData(rowTest).hitObjectColliderisGraffiti  = [interpolatedData(rowTest).hitObjectColliderisGraffiti,interpolatedData(index:index+1).hitObjectColliderisGraffiti];

                        % hdm information
                        interpolatedData(rowTest).hmdPosition_x  = [interpolatedData(rowTest).hmdPosition_x,interpolatedData(index:index+1).hmdPosition_x] ;
                        interpolatedData(rowTest).hmdPosition_y  = [interpolatedData(rowTest).hmdPosition_y,interpolatedData(index:index+1).hmdPosition_y] ;
                        interpolatedData(rowTest).hmdPosition_z  = [interpolatedData(rowTest).hmdPosition_z ,interpolatedData(index:index+1).hmdPosition_z] ;

                        interpolatedData(rowTest).hmdDirectionForward_x  = [interpolatedData(rowTest).hmdDirectionForward_x,interpolatedData(index:index+1).hmdDirectionForward_x ];
                        interpolatedData(rowTest).hmdDirectionForward_y  = [interpolatedData(rowTest).hmdDirectionForward_y,interpolatedData(index:index+1).hmdDirectionForward_y ];
                        interpolatedData(rowTest).hmdDirectionForward_z  = [interpolatedData(rowTest).hmdDirectionForward_z,interpolatedData(index:index+1).hmdDirectionForward_z ];

                        interpolatedData(rowTest).hmdRotation_x  = [interpolatedData(rowTest).hmdRotation_x ,interpolatedData(index:index+1).hmdRotation_x];
                        interpolatedData(rowTest).hmdRotation_y  = [interpolatedData(rowTest).hmdRotation_y ,interpolatedData(index:index+1).hmdRotation_y];
                        interpolatedData(rowTest).hmdRotation_z  = [interpolatedData(rowTest).hmdRotation_z, interpolatedData(index:index+1).hmdRotation_z];

                        % body and player information
                        interpolatedData(rowTest).playerBodyPosition_x  = [interpolatedData(rowTest).playerBodyPosition_x,interpolatedData(index:index+1).playerBodyPosition_x];
                        interpolatedData(rowTest).playerBodyPosition_y  = [interpolatedData(rowTest).playerBodyPosition_y,interpolatedData(index:index+1).playerBodyPosition_y];
                        interpolatedData(rowTest).playerBodyPosition_z  = [interpolatedData(rowTest).playerBodyPosition_z,interpolatedData(index:index+1).playerBodyPosition_z];

                        interpolatedData(rowTest).bodyTrackerPosition_x  = [interpolatedData(rowTest).bodyTrackerPosition_x,interpolatedData(index:index+1).bodyTrackerPosition_x];
                        interpolatedData(rowTest).bodyTrackerPosition_y  = [interpolatedData(rowTest).bodyTrackerPosition_y,interpolatedData(index:index+1).bodyTrackerPosition_y];
                        interpolatedData(rowTest).bodyTrackerPosition_z  = [interpolatedData(rowTest).bodyTrackerPosition_z,interpolatedData(index:index+1).bodyTrackerPosition_z];

                        interpolatedData(rowTest).bodyTrackerRotation_x  = [interpolatedData(rowTest).bodyTrackerRotation_x,interpolatedData(index:index+1).bodyTrackerRotation_x];
                        interpolatedData(rowTest).bodyTrackerRotation_y  = [interpolatedData(rowTest).bodyTrackerRotation_y,interpolatedData(index:index+1).bodyTrackerRotation_y];
                        interpolatedData(rowTest).bodyTrackerRotation_z  = [interpolatedData(rowTest).bodyTrackerRotation_z,interpolatedData(index:index+1).bodyTrackerRotation_z];

                        % eye information
                        interpolatedData(rowTest).eyeOpennessLeft  = [interpolatedData(rowTest).eyeOpennessLeft,interpolatedData(index:index+1).eyeOpennessLeft] ;
                        interpolatedData(rowTest).eyeOpennessRight  = [interpolatedData(rowTest).eyeOpennessRight,interpolatedData(index:index+1).eyeOpennessRight] ;
                        interpolatedData(rowTest).pupilDiameterMillimetersLeft = [interpolatedData(rowTest).pupilDiameterMillimetersLeft,interpolatedData(index:index+1).pupilDiameterMillimetersLeft];
                        interpolatedData(rowTest).pupilDiameterMillimetersRight = [interpolatedData(rowTest).pupilDiameterMillimetersRight,interpolatedData(index:index+1).pupilDiameterMillimetersRight];

                        interpolatedData(rowTest).eyePositionCombinedWorld_x  = [interpolatedData(rowTest).eyePositionCombinedWorld_x,interpolatedData(index:index+1).eyePositionCombinedWorld_x] ;
                        interpolatedData(rowTest).eyePositionCombinedWorld_y  = [interpolatedData(rowTest).eyePositionCombinedWorld_y,interpolatedData(index:index+1).eyePositionCombinedWorld_y];
                        interpolatedData(rowTest).eyePositionCombinedWorld_z  = [interpolatedData(rowTest).eyePositionCombinedWorld_z,interpolatedData(index:index+1).eyePositionCombinedWorld_z];

                        interpolatedData(rowTest).eyeDirectionCombinedWorld_x  = [interpolatedData(rowTest).eyeDirectionCombinedWorld_x,interpolatedData(index:index+1).eyeDirectionCombinedWorld_x];
                        interpolatedData(rowTest).eyeDirectionCombinedWorld_y  = [interpolatedData(rowTest).eyeDirectionCombinedWorld_y ,interpolatedData(index:index+1).eyeDirectionCombinedWorld_y];
                        interpolatedData(rowTest).eyeDirectionCombinedWorld_z  = [interpolatedData(rowTest).eyeDirectionCombinedWorld_z,interpolatedData(index:index+1).eyeDirectionCombinedWorld_z];

                        interpolatedData(rowTest).eyeDirectionCombinedLocal_x  = [interpolatedData(rowTest).eyeDirectionCombinedLocal_x,interpolatedData(index:index+1).eyeDirectionCombinedLocal_x];
                        interpolatedData(rowTest).eyeDirectionCombinedLocal_y  = [interpolatedData(rowTest).eyeDirectionCombinedLocal_y,interpolatedData(index:index+1).eyeDirectionCombinedLocal_y];
                        interpolatedData(rowTest).eyeDirectionCombinedLocal_z  = [interpolatedData(rowTest).eyeDirectionCombinedLocal_z,interpolatedData(index:index+1).eyeDirectionCombinedLocal_z];
        
                        
                        
                    else
                        problem = problem +1;
                        disp('there is a problem' + problem);
                    end

                    
                    % mark the lines for removal.
                    
                    removeRows(index) = 1; 
                    removeRows(index+1) = 1;

                %% if houses are different - do nothing
                
                

                    
                end   

            end
          
            end
          
            
        end
        
        %% remove all marked rows from interpolatedData and save them into
        % interpolatedCollider files
        

        interpolatedData(removeRows) = [];
        
        save([savepath num2str(currentPart) '_interpolatedColliders_5Sessions_WB.mat'],'interpolatedData');
           
        % doublecheck cleaning: 
         
        secondSum = sum([interpolatedData.sampleNr]);
        checkInterpolation = [checkInterpolation; currentPart, firstSum, secondSum ];
        toc
        
        
    else
        disp('something went really wrong with participant list');
    end

end

checkInterpolation = [checkInterpolation; 0, sum(checkInterpolation(:,2)), sum(checkInterpolation(:,3))];

disp(strcat(num2str(Number), ' Participants analysed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(strcat(savepath,'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');

disp('done');