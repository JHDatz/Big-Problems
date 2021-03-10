M = csvread('Data_BigFile.csv', 1, 0);
M(:,1) = []; % Reading data into MATLAB

M = M(randperm(size(M,1)), :); % Randomizes data for partitioning

CV_start = ceil(0.7*(size(M,1))); % Marks start of CV set

CV_set = M([CV_start:size(M,1)],:); % Partitions CV data from set

M([CV_start:size(M,1)],:) = []; % Removes CV for training

CV_y = CV_set(:,1); % Removes output from rest of data
CV_set(:,1) = [];

y = M(:,1); % Separates output from rest of data
M(:,1) = [];

model = svmtrain(y,M);

[prediction, accuracy, prob_estimates] = svmpredict(CV_y, CV_set, model);

disp(accuracy)