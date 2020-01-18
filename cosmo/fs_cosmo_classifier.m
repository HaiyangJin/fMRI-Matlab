function [classOut, classNames, nClass] = fs_cosmo_classifier(classifiers)

% Inputs:
%    classifier_in      the classifiers used in this analyses. Could be
%                       double (1, 2, 3, 4, 5) or strings ('libsvm', 'bayes',
%                       'lda', '_svm') or function handles. Default is 1.
% Output:
%    classifier_out     a cell contains the classifiers
%
% Created by Haiyang Jin (9/12/2019)

if nargin < 1 || isempty(classifiers)
    classifiers = 1;
end

% classifiers
classifierList = {@cosmo_classify_libsvm, ...
    @cosmo_classify_nn, ...
    @cosmo_classify_naive_bayes,...
    @cosmo_classify_lda, ...
    @cosmo_classify_svm};
classifierListNames=cellfun(@func2str,classifierList,'UniformOutput',false);

if isnumeric(classifiers) % double input
    classifiers = classifierList(classifiers);
    
elseif iscell(classifiers) % cell input
    % convert strings in cell to function handle if possible
    
    % all the strings in the cell
    isstr_class = cellfun(@isstr, classifiers);
    
    % if the functional handles could be found for the strings
    isvalid_class = isstr_class;
    isvalid = cellfun(@(x) any(contains(classifierListNames, x)), ...
        classifiers(isstr_class));

    if ~all(isvalid)
        strclass = classifiers(isstr_class);
        warning('Cannot find classifier of ''%s''.', strclass{~isvalid});
    end
    
    isvalid_class(isstr_class) = isvalid;
    
    is_class = cellfun(@(x) find(contains(classifierListNames, x)), ...
        classifiers(isvalid_class));
    
    % convert strings to function handle
    classifiers(isvalid_class) = classifierList(is_class);
    
elseif ischar(classifiers)  % string input
    classifiers= classifierList(contains(classifierListNames, classifiers));
end

% remove non-function handles
classOut = classifiers(cellfun(@(x) isa(x, 'function_handle'), classifiers));
nClass = numel(classOut);

% display the classifiers used
classNames=cellfun(@func2str,classifiers,'UniformOutput',false);
fprintf('\n\nUsing %d classifiers: %s.\n', length(classNames), ...
    cosmo_strjoin(classNames, ', '));

end