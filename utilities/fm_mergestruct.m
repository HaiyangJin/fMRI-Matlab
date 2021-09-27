function S = fm_mergestruct(varargin)
% S = fm_mergestruct(struct1, struct2, ..., 'param1',value1,'param2',value2,...)
%
% This whole function is copied from mergestruct.m (made by Kendrick) 
% https://github.com/kendrickkay/knkutils.git
% 
% Merge fields from two or more structures or from a param/val list
% Repeated fieldnames are simply overwritten, so this can be used in place
%  of struct(...) for cases where there may be duplicate field names 
%
% Example 1: 
%  >> s1=struct('foo',7,'bar','some string');
%  >> s2=struct('foo',14,'something',25);
%  >> s3 = fm_mergestruct(s1,s2)
%  s3 = 
%     foo: 14
%     bar: 'some string'
%     something: 25
%
%  >> s4 = fm_mergestruct(s3,'foo',32,'code,'helloworld')
%  s4 = 
%     foo: 32
%     bar: 'some string'
%     something: 25
%     code: 'helloworld'
%
% Example 2: 
%  >> s1=fm_mergestruct('foo',7,'bar','some string','foo',32);
%  s1 = 
%     foo: 32
%     bar: 'some string'


S = struct();

args=varargin;
structend = find(~cellfun(@isstruct,args),1,'first');
if(~isempty(structend))

   	cellend = find(~cellfun(@isstruct,args) & ~cellfun(@iscell,args),1,'first');
    if(~isempty(cellend))
        paramvals=cat(2,args{structend:cellend-1});
        paramvals=[paramvals args(cellend:end)];
    else
        paramvals=args{structend:end};

    end

    if(mod(numel(paramvals),2))
        error('need even number of fields/values');
    end
    
    fnames = paramvals(1:2:end);
    vals = paramvals(2:2:end);
    if(~all(cellfun(@ischar,fnames)))
        error('field names must be strings');
    end
    
    Stmp=struct();
    for i = 1:numel(fnames)
        Stmp.(fnames{i})=vals{i};
    end
    
    
    args = {args{1:structend-1} Stmp};
end

for i = 1:numel(args)
    v = args{i};
    fnames = fieldnames(v);
    for f = 1:numel(fnames)
        S.(fnames{f}) = v.(fnames{f});
    end
end