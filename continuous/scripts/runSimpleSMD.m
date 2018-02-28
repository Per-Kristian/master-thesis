function runSimpleSMD(user, imposter, probeSets, setType, monoRefs, ...
	diRefs, fast, paramnote, resultnote)
%Expects either an integer or 'all'. Runs the authentication system with
%either a specific user or all users, specifically using simple Scaled 
%Manhattan Distance based on mean and standard deviation.
%	The user parameter is expected to be an int between 1 and 57 for a
%	specific user, or 'all' for analyzing performance on all users.
%	The imposter parameter is expected to be 'all' for testing with all
%	imposters, or an integer representing a single imposter user, which can
%	also be the user themself. In such a case, the 'imposter' is really the
%	genuine user.

tic
params.rwrdThreshold = 1.85;
params.width = 0.28;
params.maxRwrd = 1;
params.maxPen = 1;
params.singleOccScore = 3;
params.missingScore = 3.3;
params.lockout = 90;
params.type = 'simpleSMD';
params.note = paramnote;

runner = Runner(user, imposter, params, probeSets, setType, monoRefs, ...
	diRefs, fast, resultnote);
runner.run();

toc
end