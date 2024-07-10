%% ---------------------step2_clean_Participants_V3.m----------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description:
% step 2 in pre-processing pipeline
% Script identifies the participants that have more than 30% of their data 
% labeled missing data (noData), thus, data samples during which pupil 
% recognition was below 50%. It also creates a new participant list 


% Input: 
% overviewAnalysis.mat = file created when running script
%                        step1_condenseRawData_V3.m
% Output: 
% newParticipantList     = file containing the cleaned participant list
% NewDataOverview        = data overview of the participants who are in the 
%                          new list
% discartedDataOverview  = data overview of the removed participants

%% adjust the following variables: savepath, current folder and participant list!-----------

clear all;

savepath = '../';

cd '../Data/preprocessing-pipeline/condensed-colliders/'

% Participant list of all participants that participated at least 3
% sessions in the Seahaven - 90min

PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020};
%-------------------------------------------------------------------------------------------------

% load overview fixated_vs_noise
overviewAnalysis = load('OverviewAnalysis.mat');
overviewAnalysis = overviewAnalysis.overviewAnalysis;

% create table with all participants that have less than 30% data discarted
lessThan30 = overviewAnalysis{:,4} < 30;
lessThan30Table = overviewAnalysis(lessThan30,:);

% save list of participants, that have less than 30% data discarted
newParticipantList = lessThan30Table{:,1}';
Number= length(newParticipantList);
save(strcat(savepath, 'newParticipantList'),'newParticipantList');

% analyse data of new participant list
summaryNewData = array2table(zeros(1,3),'VariableNames',{'Min','Max','Average'});
summaryNewData.Min(1) = min(lessThan30Table{:,4});
summaryNewData.Max(1) = max(lessThan30Table{:,4});
summaryNewData.Average(1) = mean(lessThan30Table{:,4});

save(strcat(savepath, 'NewDataOverview'), 'summaryNewData');

discarted= overviewAnalysis{:,4} >= 30;
discartedDataOverview= overviewAnalysis(discarted,:);
save(strcat(savepath, 'discartedDataOverview'), 'discartedDataOverview');
testMean = mean(discartedDataOverview.percentage);
        

disp('done');

