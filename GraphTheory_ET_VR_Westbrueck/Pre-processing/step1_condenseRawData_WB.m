%% --------------------- step1_condenseRawData_WB.m------------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description: 
% First script to run in pre-processing pipeline
% Reads in raw csv file recorded in the Westbrook project
% and condenses data, so that directly
% consecutive instances of raycast hits on the same collider are merged into 
% one row (hit point clusters). All other columns are moved into arrays 
% into each row accordingly.

% Input: 
% uses 1004_Expl_S_1_ET_1_flattened.csv file
% Output: 
% condensedColliders_WB.mat     = new data files with each row containing 
%                                 the data of a hit point cluster
% OverviewAnalysis.mat          = summary of number and percentage of data
%                                 rows with noData (= missing data samples)
%                                 for each participant
% Missing_Participant_Files.mat = contains all participant numbers where the
%                                  data file could not be loaded

clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

savepathNewData = '../preprocessing-pipeline/renamed-colliders/';
savepathCondensedData = '../preprocessing-pipeline/condensed-colliders/';

cd '../Data/preprocessed/'

% Participant list of all participants that participated 5 sessions x 30 min 
% in Westbrook city
PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020};

colliderList = readtable('../../additional_Files/building_collider_list.csv');

changedColliders = readtable('../../additional_Files/list_collider_changes.csv');


%% --------------------------------------------------------------------------


Number = length(PartList);
noFilePartList = [Number];
missingFiles = table;

overviewAllColliders = table;
overviewRemainingColliders = table;
overviewRenamedGraffiti = table;

overviewMissingData = table;

overviewAnalysis = array2table(zeros(Number,4));
overviewAnalysis.Properties.VariableNames = {'Participant','noData_Rows','total_Rows','percentage'};


% loop code over all participants in participant list

for indexPart = 1:Number
    
    disp(['Paritipcant ', num2str(indexPart)])
    currentPart = cell2mat(PartList(indexPart));
   
    
    % loop over recording sessions
    for indexSess = 1:5
        tic
        % get eye tracking sessions and loop over them (amount of ET files
        % can vary
        dirSess = dir([num2str(currentPart) '_Expl_S_' num2str(indexSess) '*_flattened.csv']);
        
        if isempty(dirSess)
            
            hMF = table;
            hMF.Participant = currentPart;
            hMF.Session = indexSess;
            missingFiles = [missingFiles; hMF];
        
        else
            %% Main part - runs if files exist!        
            % loop over ET sessions and check data            
            for indexET = 1:length(dirSess)
                disp(['Process file: ', num2str(currentPart), '_Session_', num2str(indexSess),'_ET_', num2str(indexET)]);
                % read in the data
                data = readtable(dirSess(indexET).name);
        
                totalRows = height(data);
                
                overviewAllColliders = [overviewAllColliders; unique(data.hitObjectColliderName_1); unique(data.hitObjectColliderName_2)];
                
                %% Rename Colliders etc - everything related to Westbrook's design
                
                % go through list that identifies which collider must be
                % renamed to another name (source name rename to target
                % name)
                % do this for both first and second order hit points
                for indexCC = 1: height(changedColliders)
                    
                    sourceName = changedColliders.source_collider_name(indexCC);
                    
                    locData1 = strcmp(sourceName, data.hitObjectColliderName_1);
                    locData2 = strcmp(sourceName, data.hitObjectColliderName_2);
                    
                    % now rename name all relevant variable at these locations
                    % orginal hit 1
                    data.hitObjectColliderName_1(locData1) = changedColliders.target_collider_name(indexCC);
                    data.hitObjectColliderBoundsCenter_x_1(locData1) = changedColliders.ColliderBoundsCenter_x(indexCC);
                    data.hitObjectColliderBoundsCenter_y_1(locData1) = changedColliders.ColliderBoundsCenter_y(indexCC);
                    data.hitObjectColliderBoundsCenter_z_1(locData1) = changedColliders.ColliderBoundsCenter_z(indexCC);
                    
                    % orginal hit 2
                    data.hitObjectColliderName_2(locData2) = changedColliders.target_collider_name(indexCC);
                    data.hitObjectColliderBoundsCenter_x_2(locData2) = changedColliders.ColliderBoundsCenter_x(indexCC);
                    data.hitObjectColliderBoundsCenter_y_2(locData2) = changedColliders.ColliderBoundsCenter_y(indexCC);
                    data.hitObjectColliderBoundsCenter_z_2(locData2) = changedColliders.ColliderBoundsCenter_z(indexCC);                    
                    
                end
                                
                %% Replace body hits if possible
                % if the invisible player avatar was hit, replace the first
                % order hit point with the second order hit point, if
                % second order hit point is not a body hit
                
                locBodyV = strcmp({'Body'}, data.hitObjectColliderName_1) & not(strcmp({'Body'}, data.hitObjectColliderName_2));
                
                % now replace all first order hits with the second order
                % hit information
                data.hitObjectColliderName_1(locBodyV) = data.hitObjectColliderName_2(locBodyV);
                
                data.hitPointOnObject_x_1(locBodyV) = data.hitPointOnObject_x_2(locBodyV);
                data.hitPointOnObject_y_1(locBodyV) = data.hitPointOnObject_y_2(locBodyV);
                data.hitPointOnObject_z_1(locBodyV) = data.hitPointOnObject_z_2(locBodyV);
                               
                data.hitObjectColliderBoundsCenter_x_1(locBodyV) = data.hitObjectColliderBoundsCenter_x_2(locBodyV);
                data.hitObjectColliderBoundsCenter_y_1(locBodyV) = data.hitObjectColliderBoundsCenter_y_2(locBodyV);
                data.hitObjectColliderBoundsCenter_z_1(locBodyV) = data.hitObjectColliderBoundsCenter_z_2(locBodyV);
                
                %% Rename Graffi hits to the building but keep information in extra var
                
                findGr1 = contains(data.hitObjectColliderName_1,'Graffity');
                findGr2 = contains(data.hitObjectColliderName_2,'Graffity');
                
                data.hitObjectColliderisGraffiti_1 = findGr1;
                data.hitObjectColliderisGraffiti_2 = findGr2;
                
                graffitiNames = unique([unique(data.hitObjectColliderName_1(findGr1));unique(data.hitObjectColliderName_2(findGr2))]);
                helperG = table;
                helperG.GraffitiNames = graffitiNames;
                
                %now go through all Graffiti names and rename them using
                %the house list
                
                for indexGR = 1:length(graffitiNames)
                   
                    nameG = graffitiNames(indexGR);
                    locG1 = strcmp(nameG, data.hitObjectColliderName_1);
                    locG2 = strcmp(nameG, data.hitObjectColliderName_2);
                    
                    % identify the name of the belonging collider and
                    % ColliderBounds Koordinates
                    splitName = split(nameG, "_");
                    nr = splitName{2,1};
                    
                    % if the number is below 10, remove the 0 in front of it to match house names!
                    if startsWith(nr,'0')
                        nr = nr(2:end);
                    end
                    
                    % identify all the house info for renaming
                    graffBuilding = {strcat('TaskBuilding_', nr)};
                    
                    locList = find(strcmp(graffBuilding, colliderList.target_collider_name),1);
                    collBoundsCenter_x = colliderList.ColliderBoundsCenter_x(locList);
                    collBoundsCenter_y = colliderList.ColliderBoundsCenter_y(locList);                    
                    collBoundsCenter_z = colliderList.ColliderBoundsCenter_z(locList);
                    
                    % rename all instances of the graffiti collider and
                    % general coordinates 
                    % ordinal hit 1
                    data.hitObjectColliderName_1(locG1) = graffBuilding;
                    data.hitObjectColliderBoundsCenter_x_1(locG1) = collBoundsCenter_x;
                    data.hitObjectColliderBoundsCenter_y_1(locG1) = collBoundsCenter_y;
                    data.hitObjectColliderBoundsCenter_z_1(locG1) = collBoundsCenter_z;
                    
                    % ordinal hit 2
                    data.hitObjectColliderName_2(locG2) = graffBuilding;
                    data.hitObjectColliderBoundsCenter_x_2(locG2) = collBoundsCenter_x;
                    data.hitObjectColliderBoundsCenter_y_2(locG2) = collBoundsCenter_y;
                    data.hitObjectColliderBoundsCenter_z_2(locG2) = collBoundsCenter_z;
                    
                    
                    % save how collider was renamed and add it to overview
                    % only if helperG is not empty
                    
                    if height(helperG) > 0
                        
                        helperG.RenamedTo(indexGR) = graffBuilding;
                        
                    end
    
                end
                % add graffiti info of this file to overview
                % only if helperG is not empty
                
                if height(helperG) > 0
                    
                    overviewRenamedGraffiti = [overviewRenamedGraffiti; helperG];                    
                    
                end
                

                %% Rename everything that is not in the house list to NH
                
                uniqueBuildingNames = unique(colliderList.target_collider_name);
                isInColliderList1 = false(height(data),1);
                isInColliderList2 = false(height(data),1);
                for indexNH = 1: length(uniqueBuildingNames)
                    
                    currentB = uniqueBuildingNames(indexNH);
                    locBuilding1 = strcmp(currentB, data.hitObjectColliderName_1);
                    
                    isInColliderList1 = isInColliderList1 | locBuilding1;
                    
                    locBuilding2 = strcmp(currentB, data.hitObjectColliderName_2);
                    
                    isInColliderList2 = isInColliderList2 | locBuilding2;
                    
                end
                
                data.hitObjectColliderName_1(not(isInColliderList1)) = {'NH'};
                
                data.hitObjectColliderName_2(not(isInColliderList2)) = {'NH'};
                
                %% if second order hit is not NH, use it instead

                % if there is a first order hit and it is is a NH and the second order is
                % not, rename all second order info to first order info
                
                
                secondHitinList = not(isInColliderList1)& isInColliderList2;
                
                data.hitObjectColliderName_1(secondHitinList) = data.hitObjectColliderName_2(secondHitinList);
                
                data.hitPointOnObject_x_1(secondHitinList) = data.hitPointOnObject_x_2(secondHitinList);
                data.hitPointOnObject_y_1(secondHitinList) = data.hitPointOnObject_y_2(secondHitinList);
                data.hitPointOnObject_z_1(secondHitinList) = data.hitPointOnObject_z_2(secondHitinList);
                               
                data.hitObjectColliderBoundsCenter_x_1(secondHitinList) = data.hitObjectColliderBoundsCenter_x_2(secondHitinList);
                data.hitObjectColliderBoundsCenter_y_1(secondHitinList) = data.hitObjectColliderBoundsCenter_y_2(secondHitinList);
                data.hitObjectColliderBoundsCenter_z_1(secondHitinList) = data.hitObjectColliderBoundsCenter_z_2(secondHitinList);
                
                                
                
                
                %% identify the bad data samples with not enough eye tracking validity
                
                notCombinedEyes3 = not(data.combinedGazeValidityBitmask == 3);
                
                data.hitObjectColliderName_1(notCombinedEyes3) = {'noData'};
                
                data.hitPointOnObject_x_1(notCombinedEyes3) = NaN;
                data.hitPointOnObject_y_1(notCombinedEyes3) = NaN;
                data.hitPointOnObject_z_1(notCombinedEyes3) = NaN;
                
                data.hitObjectColliderBoundsCenter_x_1(notCombinedEyes3) = NaN;
                data.hitObjectColliderBoundsCenter_y_1(notCombinedEyes3) = NaN;
                data.hitObjectColliderBoundsCenter_z_1(notCombinedEyes3) = NaN;
                
                missingDataSum = sum(notCombinedEyes3);
                
        
                
                %% select all data variable that will included in the further pre-processing
                % also make sure that from now on, all variables are in the
                % same order (json does not guarantee for that, as dictionaries do not keep order)
                dataNew = table;
                
                % timestamps
                dataNew.timeStampDataPointStart = data.timeStampDataPointStart;
                dataNew.timeStampDataPointEnd  = data.timeStampDataPointEnd;
                dataNew.timeStampGetVerboseData  = data.timeStampGetVerboseData;
                
                % raycast information
                dataNew.hitObjectColliderName  = data.hitObjectColliderName_1;
                
                dataNew.hitPointOnObject_x  = data.hitPointOnObject_x_1;
                dataNew.hitPointOnObject_y  = data.hitPointOnObject_y_1;
                dataNew.hitPointOnObject_z  = data.hitPointOnObject_z_1 ;
                
                dataNew.hitObjectColliderBoundsCenter_x = data.hitObjectColliderBoundsCenter_x_1;
                dataNew.hitObjectColliderBoundsCenter_y = data.hitObjectColliderBoundsCenter_y_1;
                dataNew.hitObjectColliderBoundsCenter_z = data.hitObjectColliderBoundsCenter_z_1;
                
                dataNew.hitObjectColliderisGraffiti  = data.hitObjectColliderisGraffiti_1;
                
                % hdm information
                dataNew.hmdPosition_x  = data.hmdPosition_x ;
                dataNew.hmdPosition_y  = data.hmdPosition_y ;
                dataNew.hmdPosition_z  = data.hmdPosition_z ;
                
                dataNew.hmdDirectionForward_x  = data.hmdDirectionForward_x ;
                dataNew.hmdDirectionForward_y  = data.hmdDirectionForward_y ;
                dataNew.hmdDirectionForward_z  = data.hmdDirectionForward_z ;
                
                dataNew.hmdRotation_x  = data.hmdRotation_x ;
                dataNew.hmdRotation_y  = data.hmdRotation_y;
                dataNew.hmdRotation_z  = data.hmdRotation_z;
                
                % body and player information
                dataNew.playerBodyPosition_x  = data.playerBodyPosition_x;
                dataNew.playerBodyPosition_y  = data.playerBodyPosition_y;
                dataNew.playerBodyPosition_z  = data.playerBodyPosition_z;
                
                dataNew.bodyTrackerPosition_x  = data.bodyTrackerPosition_x;
                dataNew.bodyTrackerPosition_y  = data.bodyTrackerPosition_y;
                dataNew.bodyTrackerPosition_z  = data.bodyTrackerPosition_z;
                
                dataNew.bodyTrackerRotation_x  = data.bodyTrackerRotation_x;
                dataNew.bodyTrackerRotation_y  = data.bodyTrackerRotation_y;
                dataNew.bodyTrackerRotation_z  = data.bodyTrackerRotation_z;
                
                % eye information
                dataNew.eyeOpennessLeft  = data.eyeOpennessLeft ;
                dataNew.eyeOpennessRight  = data.eyeOpennessRight ;
                
                dataNew.pupilDiameterMillimetersLeft = data.pupilDiameterMillimetersLeft;
                dataNew.pupilDiameterMillimetersRight = data.pupilDiameterMillimetersRight;
                
                dataNew.eyePositionCombinedWorld_x  = data.eyePositionCombinedWorld_x ;
                dataNew.eyePositionCombinedWorld_y  = data.eyePositionCombinedWorld_y;
                dataNew.eyePositionCombinedWorld_z  = data.eyePositionCombinedWorld_z;
                
                dataNew.eyeDirectionCombinedWorld_x  = data.eyeDirectionCombinedWorld_x;
                dataNew.eyeDirectionCombinedWorld_y  = data.eyeDirectionCombinedWorld_y;
                dataNew.eyeDirectionCombinedWorld_z  = data.eyeDirectionCombinedWorld_z;
                
                dataNew.eyeDirectionCombinedLocal_x  = data.eyeDirectionCombinedLocal_x;
                dataNew.eyeDirectionCombinedLocal_y  = data.eyeDirectionCombinedLocal_y;
                dataNew.eyeDirectionCombinedLocal_z  = data.eyeDirectionCombinedLocal_z;


                %% update overviews and save the renamed data as table
                % overviewRemainingCollider witht the colliders that are now in the list = double check renaming
                
                overviewRemainingColliders = [overviewRemainingColliders; unique(data.hitObjectColliderName_1)];
%                 
                % update data overviewMissing data:
                              
                helperOA = table;
                
                helperOA.Participant = currentPart;
                helperOA.noData_Rows = missingDataSum;
                helperOA.total_Rows = totalRows;
                helperOA.percentage = missingDataSum * 100 / totalRows;

                
                
                overviewMissingData = [overviewMissingData; helperOA];
                overviewAnalysis = [overviewAnalysis; helperOA];
                
                % save the renamed and reduced file
                
                writetable(dataNew, [savepathNewData num2str(currentPart) '_Session_' num2str(indexSess) '_ET_' num2str(indexET) '_rawData_renamedColliders.csv']);
                

                %% create the condensed viewed houses list  

                helperT = table;
                helperT.sampleNr = 1;
                helperT.clusterDuration = dataNew.timeStampDataPointStart(1); % will be overwritten anyway, just to ensure, data type has enough digits
                helperT = [helperT,dataNew(1,:)];
                condensedData = table2struct(helperT);


                % additional variables
%                 previous = condensedData(1).hitObjectColliderName;
%                 time = 1000/30;
                indexCluster=1;
                clusterStartinData = 1;
                clusterEndinData = 1;


                %% Condensation part: condense the data into clusters
                heightDataNew = height(dataNew);
                for indexPosinData= 2: heightDataNew

                    %check if same or another collider was seen
                    % check if the data sample belongs to the ongoing
                    % cluster - if yes, update the end index of the cluster
                    
                    if strcmp(condensedData(indexCluster).hitObjectColliderName, dataNew.hitObjectColliderName{indexPosinData}) && indexPosinData < heightDataNew
                        
                        clusterEndinData = indexPosinData;
                        

%                     if collider at the current data index is not
%                     identical with the collider of the ongoing cluster,
%                     add cluster information and reset start and end index
%                     of the cluster
                    else

                        % add the cluster data to the condensedData struct
                        
                        % to calculate the cluster duration, we will use
                        % the data point start time stamp
                        % so we will substract the start point of this cluster
                        % from the start point of the next cluster 
                        % also we will multiply the result with 1000 to get
                        % milliseconds
                        
                        % add an exception for the last row of the data
                        % file (to avoid the index running out of bound)
                        if (indexPosinData == heightDataNew)   
                            
                            clusterEndinData = indexPosinData;

                            condensedData(indexCluster).clusterDuration = (dataNew.timeStampDataPointStart(clusterEndinData) - dataNew.timeStampDataPointStart(clusterStartinData))*1000;

                            
                        else
                            condensedData(indexCluster).clusterDuration = (dataNew.timeStampDataPointStart(clusterEndinData+1) - dataNew.timeStampDataPointStart(clusterStartinData))*1000;
                            
                        end
                        
                        % amount of condensed samples
                        condensedData(indexCluster).sampleNr = clusterEndinData - clusterStartinData +1;

                        
                        % timestamps
                        condensedData(indexCluster).timeStampDataPointStart = dataNew.timeStampDataPointStart(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).timeStampDataPointEnd  = dataNew.timeStampDataPointEnd(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).timeStampGetVerboseData  = dataNew.timeStampGetVerboseData(clusterStartinData:clusterEndinData)';

                        % raycast information
                        condensedData(indexCluster).hitPointOnObject_x  = dataNew.hitPointOnObject_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).hitPointOnObject_y  = dataNew.hitPointOnObject_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).hitPointOnObject_z  = dataNew.hitPointOnObject_z(clusterStartinData:clusterEndinData)' ;

                        condensedData(indexCluster).hitObjectColliderBoundsCenter_x = dataNew.hitObjectColliderBoundsCenter_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).hitObjectColliderBoundsCenter_y = dataNew.hitObjectColliderBoundsCenter_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).hitObjectColliderBoundsCenter_z = dataNew.hitObjectColliderBoundsCenter_z(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).hitObjectColliderisGraffiti  = dataNew.hitObjectColliderisGraffiti(clusterStartinData:clusterEndinData)';

                        % hdm information
                        condensedData(indexCluster).hmdPosition_x  = dataNew.hmdPosition_x(clusterStartinData:clusterEndinData)' ;
                        condensedData(indexCluster).hmdPosition_y  = dataNew.hmdPosition_y(clusterStartinData:clusterEndinData)' ;
                        condensedData(indexCluster).hmdPosition_z  = dataNew.hmdPosition_z(clusterStartinData:clusterEndinData)' ;

                        condensedData(indexCluster).hmdDirectionForward_x  = dataNew.hmdDirectionForward_x(clusterStartinData:clusterEndinData)' ;
                        condensedData(indexCluster).hmdDirectionForward_y  = dataNew.hmdDirectionForward_y(clusterStartinData:clusterEndinData)' ;
                        condensedData(indexCluster).hmdDirectionForward_z  = dataNew.hmdDirectionForward_z(clusterStartinData:clusterEndinData)' ;

                        condensedData(indexCluster).hmdRotation_x  = dataNew.hmdRotation_x(clusterStartinData:clusterEndinData)' ;
                        condensedData(indexCluster).hmdRotation_y  = dataNew.hmdRotation_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).hmdRotation_z  = dataNew.hmdRotation_z(clusterStartinData:clusterEndinData)';

                        % body and player information
                        condensedData(indexCluster).playerBodyPosition_x  = dataNew.playerBodyPosition_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).playerBodyPosition_y  = dataNew.playerBodyPosition_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).playerBodyPosition_z  = dataNew.playerBodyPosition_z(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).bodyTrackerPosition_x  = dataNew.bodyTrackerPosition_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).bodyTrackerPosition_y  = dataNew.bodyTrackerPosition_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).bodyTrackerPosition_z  = dataNew.bodyTrackerPosition_z(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).bodyTrackerRotation_x  = dataNew.bodyTrackerRotation_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).bodyTrackerRotation_y  = dataNew.bodyTrackerRotation_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).bodyTrackerRotation_z  = dataNew.bodyTrackerRotation_z(clusterStartinData:clusterEndinData)';

                        % eye information
                        condensedData(indexCluster).eyeOpennessLeft  = dataNew.eyeOpennessLeft(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyeOpennessRight  = dataNew.eyeOpennessRight(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).pupilDiameterMillimetersLeft = dataNew.pupilDiameterMillimetersLeft(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).pupilDiameterMillimetersRight = dataNew.pupilDiameterMillimetersRight(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).eyePositionCombinedWorld_x  = dataNew.eyePositionCombinedWorld_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyePositionCombinedWorld_y  = dataNew.eyePositionCombinedWorld_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyePositionCombinedWorld_z  = dataNew.eyePositionCombinedWorld_z(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).eyeDirectionCombinedWorld_x  = dataNew.eyeDirectionCombinedWorld_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyeDirectionCombinedWorld_y  = dataNew.eyeDirectionCombinedWorld_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyeDirectionCombinedWorld_z  = dataNew.eyeDirectionCombinedWorld_z(clusterStartinData:clusterEndinData)';

                        condensedData(indexCluster).eyeDirectionCombinedLocal_x  = dataNew.eyeDirectionCombinedLocal_x(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyeDirectionCombinedLocal_y  = dataNew.eyeDirectionCombinedLocal_y(clusterStartinData:clusterEndinData)';
                        condensedData(indexCluster).eyeDirectionCombinedLocal_z  = dataNew.eyeDirectionCombinedLocal_z(clusterStartinData:clusterEndinData)';
                        
                        condensedData(indexCluster).testRow = dataNew.hitObjectColliderName(clusterStartinData:clusterEndinData)';
                        
                        % reset all 3 indexssss and add next cluster
                        % collider name to the new cluster
                        
                        if (indexPosinData < heightDataNew)                            
                            
                            clusterStartinData = indexPosinData;
                            clusterEndinData = indexPosinData;   

                            indexCluster = indexCluster +1;
                            condensedData(indexCluster).hitObjectColliderName = dataNew.hitObjectColliderName(clusterStartinData);
                        end

                    end


                end


%                   save condensed data

                    save([savepathCondensedData num2str(currentPart) '_Session_' num2str(indexSess) '_ET_' num2str(indexET) '_condensedColliders_WB'],'condensedData');             
                

                
            end
            toc 
            
        end
        
          
        
    end
    
    

    
  

end            
            
% save overviews

save([savepathNewData 'overviewRenamedGraffiti'], 'overviewRenamedGraffiti');
save([savepathNewData 'overviewRemainingColliders'], 'overviewRemainingColliders');
save([savepathNewData 'overviewAllColliders'], 'overviewAllColliders');

% save missing data overview in both folders
overviewAnalysis = overviewAnalysis(2:end, :);
save([savepathNewData 'OverviewAnalysis.mat'],'overviewAnalysis');
save([savepathCondensedData 'OverviewAnalysis.mat'],'overviewAnalysis');

writetable(overviewMissingData, [savepathNewData 'overviewMissingData.csv']);
writetable(overviewMissingData, [savepathCondensedData 'overviewMissingData.csv']);

disp('saved overviews');

% save missing data info
if height(missingFiles) > 0
    disp('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!--------------------------------');
    
    disp(strcat(height(missingFiles),' files were missing'));

    writetable(missingFiles, [savepathNewData 'missingFiles.csv']);
    writetable(missingFiles, [savepathCondensedData 'missingFiles.csv']);
    disp('saved missing file list');
    
else
    
    disp('all files were found');
    
end


disp('done');
