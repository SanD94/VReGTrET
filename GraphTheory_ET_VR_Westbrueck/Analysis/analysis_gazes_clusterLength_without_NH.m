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

savepath = 'E:\Westbrueck Data\SpaRe_Data\1_Exploration\Analysis\cluster_length\more\';

cd 'E:\Westbrueck Data\SpaRe_Data\1_Exploration\Pre-processsing_pipeline\interpolatedColliders\'

% participant list of 90 min VR - only with participants who have lost less than 30% of
% their data (after running script cleanParticipants_V2)

% 20 participants with 90 min VR trainging less than 30% data loss
PartList = {1004 1005 1008 1010 1011 1013 1017 1018 1019 1021 1022 1023 1054 1055 1056 1057 1058 1068 1069 1072 1073 1074 1075 1077 1079 1080};

%----------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;
countAnalysedPart= 0;


overviewGazes= table('size',[Number,4],'VariableTypes',{'double','double','double','double'},...
                    'VariableNames',{'Participant','SumGazeSamples','SumNoiseSamples','SumAllSamples'});
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
        gazes = housesTable.durations > 250;

        
        gazedObjects = housesTable(gazes,:);
        
        noisyObjects = housesTable(not(gazes),:);
              
        
        sumG = sum([gazedObjects.durations],'omitnan');
        sumN = sum([noisyObjects.durations],'omitnan');
        overviewGazes.Participant(ii) = currentPart;
        overviewGazes.SumGazeDuration(ii) = sumG;
        overviewGazes.SumNoiseDuration(ii) = sumN;
        overviewGazes.SumAllDurations(ii) = sum(housesTable.durations,'omitnan');
        
%         figure(1)
%         pieplot= pie([sumG,sumN]);
%         legend({'gazes / bigger 7 samples','noise / smaller/equal 7 samples'},'Location','northeastoutside')
%         title(strcat('gazes noise distribution - participant: ', num2str(currentPart)))
%         savefig(gcf, strcat(savepath, num2str(currentPart) ,'_gazes_noise_distr.fig'));
%         
%         %saveas(gcf,strcat(savepath, num2str(currentPart) ,'_gazes_noise_distr.png'),'png');
%         print(gcf,strcat(savepath, num2str(currentPart) ,'_gazes_noise_distr.png'),'-dpng','-r300'); 
%         

     
  
        toc
        
    else
        disp('something went really wrong with participant list');
    end

end

%% plot pie plot of distribution gazes vs noise
avgG = mean(overviewGazes.SumGazeDuration);
avgN = mean(overviewGazes.SumNoiseDuration);

figure(2)
pieplot2 = pie([avgG, avgN]);
legend({'gazes - no NH, nodata / bigger 266,6 samples','noise / smaller/equal 266,6 samples'},'Location','northeastoutside')
title('mean gazes noise distribution')

saveas(gcf,strcat(savepath,'mean_gazes_noise_distr_NHND.png'),'png');
print(gcf,strcat(savepath,'mean_gazes_noise_distr.png_NHND'),'-dpng','-r300'); 
savefig(gcf, strcat(savepath,'mean_gazes_noise_distr_NHND.fig'));

percentage = NaN(Number,2);

percentage(:,1) = (overviewGazes.SumGazeDuration*100) ./ overviewGazes.SumAllDurations;
percentage(:,2) = (overviewGazes.SumNoiseDuration*100) ./ overviewGazes.SumAllDurations;

% figure(3)
% 
% plotty3 = boxplot(percentage(:,2));
% title('percentage of noisy data distribution over all participants')
% ylabel('percentage')
% 
% saveas(gcf,strcat(savepath,'perc_noisy_data_distr_allParts.png'),'png');
% 
% print(gcf,strcat(savepath,'perc_noisy_data_distr_allParts.png'),'-dpng','-r300'); 
% savefig(gcf, strcat(savepath,'perc_noisy_data_distr_allParts.fig'));


%% distribution of cluster sizes over all participants
figure(4)

histyAll= histogram(allDurations,'Normalization','probability');
yt = get(gca, 'YTick');  
xt = get(gca, 'XTick');
% set(gca, 'YTick',yt, 'YTickLabel',yt*100);
% set(gca, 'XTick',xt, 'XTickLabel',xt*33.33);

ax = gca;
ax.XLabel.String = 'Distribution of hit point clusters (time in ms)';
ax.XLabel.FontSize = 12;
ax.YLabel.String = 'Probability';
ax.YLabel.FontSize = 12;
saveas(gcf,strcat(savepath,'viewing_duration_all_NHND.png'),'png');

print(gcf,strcat(savepath,'viewing_duration_all_NHND.png'),'-dpng','-r300'); 
savefig(gcf, strcat(savepath,'viewing_duration_all_NHND.fig'));

%% plot durations

% big30= allSamples > 1000;
% 
% combSamples = allSamples;
% combSamples(big30) = 1001;
% 
% figure(5)
% 
% histyCombined = histogram(combSamples,'Normalization','probability');
% yt = get(gca, 'YTick');                    
% % set(gca, 'YTick',yt, 'YTickLabel',yt*100);
% % xt= [1:3:31];
% % set(gca, 'XTick',xt, 'XTickLabel',xt*33.33);
% 
% ax = gca;
% ax.XLabel.String = 'Distribution of hit point clusters (time in ms)';
% ax.XLabel.FontSize = 12;
% ax.YLabel.String = 'Probability';
% ax.YLabel.FontSize = 12;

% saveas(gcf,strcat(savepath,'viewing_duration_bigCombined.png'),'png');

% print(gcf,strcat(savepath,'viewing_duration_bigCombined.png'),'-dpng','-r300'); 
% savefig(gcf, strcat(savepath,'viewing_duration_bigCombined.fig'));

% save overviews
save([savepath 'Overview_Gazes_NHND.mat'],'overviewGazes');
% save([savepath 'allInterpolatedData.mat'],'allInterpData');
save([savepath 'allSamples_int_NHND.mat'],'allDurations');





disp(strcat(num2str(Number), ' Participants in List'));
disp(strcat(num2str(countAnalysedPart), ' Participants analyzed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(strcat(savepath,'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');



disp('done');