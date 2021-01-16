clear
data = csvread('Data_Final.csv',1,0);
%predictors = xlsread('predictors.xlsx');
data(data(:,1)>2);
readm = data(:,2);
[rowd,cold] = size(data);
for i=3:cold
    X(:,i-2) = data(:,i);
end
disp = X(1,1);
[B, FitInfoL] = lasso(X,readm, 'Alpha', .05, 'DFmax',25);
[rowLasso, colLasso] = size(B);
for i = 1:colLasso
    sumLassoCols(i) = sum(B(:,i));
end
for i = 1:rowLasso
    sumLassoRows(i) = sum(B(i,:));
end
for i = 1:colLasso
    nz(i) = nnz(B(:,i));
end
%imp = B(:,1);
%filename = 'importantData.xlsx';
%xlswrite(filename,imp,1);
