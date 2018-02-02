function [monoRefs, diRefs] = fetchRefs()
%FETCHREFS Summary of this function goes here
%   Detailed explanation goes here
for ii = 1:57
	userName = sprintf('User_%02d', ii);
	[monoRefs.(userName), diRefs.(userName)] = FileIO.readRefs(ii);
end

