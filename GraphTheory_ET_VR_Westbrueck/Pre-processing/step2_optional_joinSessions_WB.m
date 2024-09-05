%% -------------------step2_optional_join3Sessions_WB.m------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description:
% optional step after step 2 in pre-processing pipeline
% (only necessary if data acquisition was completed in several sessions)
% combines condensedColliders files of different VR sessions into one file


% Input: 
% combinedSessions_newPartNumbers.csv = list matching the different
%                                       numbers of each session to the 
%                                       respective participant (uploaded in
%                                       https://osf.io/aurjk/)
% condensedColliders_V3.mat = files created when running script
%                             step1_condenseRawData_V3.m
% uses
% Output: 
% condensedColliders3S.mat     = files combining the three sessions for
%                                each participant

clear all;

%% --------adjust the following variables savepath, cd, listpath

savepath = '../condensed-colliders-combined/';

cd '../Data/preprocessing-pipeline/condensed-colliders';

% load list that contains the participant numbers belonging together sorted
% into the different sessions (this list here is uploaded with the other
% data)


%% main code
 
PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020, 2025};

Number = length(PartList);
noFilePartList = [Number];
missingFiles = table;



% loop code over all participants in participant list

for indexPart = 1:Number
    
    disp(['Paritipcant ', num2str(indexPart)])
    currentPart = cell2mat(PartList(indexPart));
    
    condensedColliders5S = struct;
        
    
    % loop over recording sessions (should be 5 for each participant)
    for indexSess = 1
        tic
        % get eye tracking sessions and loop over them (amount of ET files
        % can vary
        dirSess = dir([num2str(currentPart) '_Session_' num2str(indexSess) '*_condensedColliders_WB.mat']);
        
        if isempty(dirSess)
            
            hMF = table;
            hMF.Participant = currentPart;
            hMF.Session = indexSess;
            missingFiles = [missingFiles; hMF];
        
        else
            %% Main part - runs if files exist!        
            % loop over ET sessions and check data
            
            dataSess = struct;
                                  
            for indexET = 1:length(dirSess)
                % read in the data
                currentET = load([num2str(currentPart) '_Session_' num2str(indexSess) '_ET_' num2str(indexET) '_condensedColliders_WB.mat']);
                currentET = currentET.condensedData;
                
                sessInfo = cell(length(currentET),1);               
                sessInfo(:) = {['Session', num2str(indexSess)]};
                [currentET.Session] = sessInfo{:};
                
                etInfo = cell(length(currentET),1);
                etInfo(:) = {['ETSession', num2str(indexET)]};
                [currentET.ETSession] = etInfo{:};
                
                currentET(end+1).hitObjectColliderName = 'newSession';
                currentET(end).sampleNr = 40;
                currentET(end).clusterDuration = 400;    
                
                if length(dataSess) ==1
                
                    dataSess = currentET;
                else

                    dataSess = [dataSess, currentET];
                end


            end

            
        end
        
        if length(condensedColliders5S) == 1
            condensedColliders5S = dataSess;

        else

            condensedColliders5S = [condensedColliders5S, dataSess];

        end
        
    end
    
    save([savepath, num2str(currentPart), '_condensedColliders5S_WB.mat'],'condensedColliders5S');
    
end


disp('done');
