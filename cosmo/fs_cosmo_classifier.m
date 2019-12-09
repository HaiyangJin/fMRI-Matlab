function [class_out, class_names, nClass] = fs_cosmo_classifier(classifier_in)

% Inputs:
%    classifier_in      the classifiers used in this analyses. Could be
%                       double (1, 2, 3, 4, 5) or strings ('libsvm', 'bayes',
%                       'lda', '_svm') or function handles. Default is 1.
% Output:
%    classifier_out     a cell contains the classifiers
%
% Created by Haiyang Jin (9/12/2019)

if nargin < 1 || isempty(classifier_in)
    classifier_in = 1;
end

% classifiers
classifierList = {@cosmo_classify_libsvm, ...
    @cosmo_classify_nn, ...
    @cosmo_classify_naive_bayes,...
    @cosmo_classify_lda, ...
    @cosmo_classify_svm};
classifierList_names=cellfun(@func2str,classifierList,'UniformOutput',false);

if isnumeric(classifier_in) % double input
    classifier_in = classifierList(classifier_in);
    
elseif iscell(classifier_in) % cell input
    % convert strings in cell to function handle if possible
    
    % all the strings in the cell
    isstr_class = cellfun(@isstr, classifier_in);
    
    % if the functional handles could be found for the strings
    isvalid_class = isstr_class;
    isvalid = cellfun(@(x) any(contains(classifierList_names, x)), ...
        classifier_in(isstr_class));

    if ~all(isvalid)
        strclass = classifier_in(isstr_class);
        warning('Cannot find classifier of ''%s''.', strclass{~isvalid});
    end
    
    isvalid_class(isstr_class) = isvalid;
    
    is_class = cellfun(@(x) find(contains(classifierList_names, x)), ...
        classifier_in(isvalid_class));
    
    % convert strings to function handle
    classifier_in(isvalid_class) = classifierList(is_class);
    
elseif ischar(classifier_in)  % string input
    classifier_in= classifierList(contains(classifierList_names, classifier_in));
end

% remove non-function handles
class_out = classifier_in(cellfun(@(x) isa(x, 'function_handle'), classifier_in));
nClass = numel(class_out);

% display the classifiers used
class_names=cellfun(@func2str,classifier_in,'UniformOutput',false);
fprintf('\n\nUsing %d classifiers: %s.\n', length(class_names), ...
    cosmo_strjoin(class_names, ', '));

end