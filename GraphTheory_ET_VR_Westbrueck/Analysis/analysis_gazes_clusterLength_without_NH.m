%% ------------------analysis_clusterLenghtWithoutNH.m------------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description: 
% 

% Input: 
% uses data file interpolatedColliders_3Sessions_V3

% Output: 
%



clear all;
%% adjust the following variables: savepath, current folder and participant list!-----------

savepath = 'F:\big-data\vr_data\Data\analysis\gaze_cluster_length\';

cd 'F:\big-data\vr_data\Data\preprocessing-pipeline\interpolated-colliders'

% participant list of 90 min VR - only with participants who have lost less than 30% of
% their data (after running script cleanParticipants_V2)

% 20 participants with 90 min VR trainging less than 30% data loss
PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020, 2025};
Group = ["Control","Control","Control","Control","Control","Control","Control","Control","Control", ...
    "Glaucoma","Glaucoma","Glaucoma","Glaucoma","Glaucoma","Glaucoma", "Glaucoma"];

%----------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;
countAnalysedPart= 0;


overviewGazes= table('size',[Number,5],'VariableTypes',{'double','double','double','double', 'string'},...
                    'VariableNames',{'Participant','SumGazeSamples','SumNoiseSamples','SumAllSamples', 'Group'});
overviewGazes.Group = Group';
allDurations = [];

% allInterpData = struct;


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
        
        % save all data into one struct --> allInterpData
        % copy the data to the struct if it is empty (first participant)
%         if(size(allInterpData) == [1 1])
%             allInterpData = interpolatedData;
%         end
%         allInterpData = [allInterpData, interpolatedData];

        dataTable = table;
        dataTable.hitObjectColliderName = [interpolatedData(:).hitObjectColliderName]';
        dataTable.durations = [interpolatedData(:).clusterDuration]';
        
        % remove all NH and sky elements
        nohouse=strcmp(dataTable.hitObjectColliderName(:),{'NH'});
        housesTable = dataTable;
        housesTable(nohouse,:)=[];
        
        noData=strcmp(housesTable.hitObjectColliderName(:),{'noData'});
        housesTable(noData,:)=[];
        
        allDurations = [allDurations; housesTable.durations];
        
        % save information about distribution of gazes and noise
        % something was fixated when having more than 7 samples
        gazes = housesTable.durations > 266.6;

        
        gazedObjects = housesTable(gazes,:);
        
        noisyObjects = housesTable(not(gazes),:);
              
        
        sumG = sum([gazedObjects.durations],'omitnan');
        sumN = sum([noisyObjects.durations],'omitnan');
        overviewGazes.Participant(ii) = currentPart;
        overviewGazes.SumGazeDuration(ii) = sumG;
        overviewGazes.SumNoiseDuration(ii) = sumN;
        overviewGazes.SumAllDurations(ii) = sum(housesTable.durations,'omitnan');
        
  
        toc
        
    else
        disp('something went really wrong with participant list');
    end

end

%% plot pie plot of distribution gazes vs noise

for condition = ["Glaucoma", "Control"]
    cur_overview_gazes = overviewGazes(overviewGazes.Group == condition, :);

    avgG = mean(cur_overview_gazes.SumGazeDuration);
    avgN = mean(cur_overview_gazes.SumNoiseDuration);
    
    figure(2)
    pieplot2 = pie([avgG, avgN]);
    legend({'gazes - no NH, nodata / bigger 266,6 samples','noise / smaller/equal 266,6 samples'},'Location','northeastoutside')
    title([condition ' mean gazes noise distribution'])
    
    saveas(gcf,strcat(savepath,condition, 'mean_gazes_noise_distr_NHND.png', "_"),'png');
    print(gcf,strcat(savepath, condition, '_mean_gazes_noise_distr_NHND.png'),'-dpng','-r300'); 
    savefig(gcf, strcat(savepath, condition, '_mean_gazes_noise_distr_NHND.fig'));
    
    percentage = NaN(height(cur_overview_gazes),2);
    
    percentage(:,1) = (cur_overview_gazes.SumGazeDuration*100) ./ cur_overview_gazes.SumAllDurations;
    percentage(:,2) = (cur_overview_gazes.SumNoiseDuration*100) ./ cur_overview_gazes.SumAllDurations;
    

end


%% distribution of cluster sizes over all participants
figure(4)

histyAll= histogram(allDurations, 1000, 'Normalization','probability');
yt = get(gca, 'YTick');  
xt = get(gca, 'XTick');
% set(gca, 'YTick',yt, 'YTickLabel',yt*100);
% set(gca, 'XTick',xt, 'XTickLabel',xt*33.33);
xlim([0 1033])
ax = gca;
ax.XLabel.String = 'Distribution of hit point clusters (time in ms)';
ax.XLabel.FontSize = 12;
ax.YLabel.String = 'Probability';
ax.YLabel.FontSize = 12;
saveas(gcf,strcat(savepath,'viewing_duration_all_NHND.png'),'png');

print(gcf,strcat(savepath,'viewing_duration_all_NHND.png'),'-dpng','-r300'); 
savefig(gcf, strcat(savepath,'viewing_duration_all_NHND.fig'));

%% plot durations

% save overviews
save([savepath 'Overview_Gazes_NHND.mat'],'overviewGazes');
save([savepath 'allSamples_int_NHND.mat'],'allDurations');




disp(strcat(num2str(Number), ' Participants in List'));
disp(strcat(num2str(countAnalysedPart), ' Participants analyzed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(strcat(savepath,'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');



disp('done');