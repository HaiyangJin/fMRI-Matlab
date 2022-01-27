function [classOut, classONames, classOShortNames, nClass] = cosmo_classifier(classifiers)
% [classOut, classNames, classShortNames, nClass] = cosmo_classifier(classifiers)
%
% This function generates the classifier related information.
%
% Inputs:
%    classifiers        <integer> or <string> or <function handle> 
%                        the classifiers used in this analyses. cn be
%                        integer (1, 2, 3, 4, 5) or strings ('libsvm', 
%                        'bayes','lda', '_svm') or function handles. 
%                        Default is 1.
% Output:
%    classOut           <cell> a cell of function handles. 
%    classONames        <cell of string> a cell of all out classifier
%                        names.
%    classOShortNames   <cell of string> the short version of out classifier
%                        names.
%    nClass             <integer> number of out classifiers.
%
% Dependency:
%    CoSMoMVPA
%
% Created by Haiyang Jin (9-Dec-2019)

if nargin < 1 || isempty(classifiers)
    classifiers = 1;
end

% classifiers
classifierList = {@cosmo_classify_libsvm, ... % 1
    @cosmo_classify_nn, ... % 2
    @cosmo_classify_naive_bayes,... % 3
    @cosmo_classify_lda, ... $ 4
    @cosmo_classify_svm}; % 5
classifierListNames=cellfun(@func2str,classifierList, 'uni',false);

if isnumeric(classifiers) % double input
    classifiers = classifierList(classifiers);
    
elseif iscell(classifiers) % cell input
    % convert strings in cell to function handle if possible
    
    % all the strings in the cell
    isstr_class = cellfun(@ischar, classifiers);
    
    % if the functional handles can be found for the strings
    isvalid_class = isstr_class;
    isvalid = cellfun(@(x) any(contains(classifierListNames, x)), ...
        classifiers(isstr_class));

    if ~all(isvalid)
        strclass = classifiers(isstr_class);
        warning('Cannot find classifier ''%s''.', strclass{~isvalid});
    end
    
    isvalid_class(isstr_class) = isvalid;
    
    is_class = cellfun(@(x) find(contains(classifierListNames, x)), ...
        classifiers(isvalid_class));
    
    % convert strings to function handle
    classifiers(isvalid_class) = classifierList(is_class);
    
elseif ischar(classifiers)  % string input
    classifiers= classifierList(contains(classifierListNames, classifiers));

elseif isa(classifiers,'function_handle')
    classifiers = {classifiers};
end

% remove non-function handles
classOut = classifiers(cellfun(@(x) isa(x, 'function_handle'), classifiers));
classONames = cellfun(@func2str,classOut, 'uni',false);
classOShortNames = cellfun(@(x) erase(x, 'cosmo_classify_'), classONames, 'uni', false);
nClass = numel(classOut);

% display the classifiers used
fprintf('\n\nUsing %d classifier(s): %s.\n', nClass, ...
    cosmo_strjoin(classONames, ', '));

end