classdef DBAccess
	%DBACCESS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess=private)
		conf
		systemType
	end
	
	methods
		function obj = DBAccess(systemType)
			%DBACCESS Construct an instance of this class
			%   Loads config from outside the repo's scope.
			obj.conf = FileIO.getDbConf(systemType);
			obj.systemType = systemType;
		end
		
		function paramID = insertParams(obj, params)
			%insertParams Inserts a set of parameters into the DB.
			%   Returns the ID of the inserted row.
			%	If identical parameters already exist, return the existing ID.
			conn = database(obj.conf.datasource, obj.conf.username, ...
				obj.conf.password, obj.conf.driver, obj.conf.url);
			tablename = 'params';
			
			[curs, colnames] = obj.fetchSpecificParams(conn, params);
			if ischar(curs.Data{1})
				% if the data is 'No Data', insert new params
				insert(conn,tablename,colnames,params);
				% Get ID of the inserted row.
				query = ('SELECT id from params WHERE ID = @@IDENTITY');
				curs = exec(conn, query);
				curs = fetch(curs);
				paramID = curs.Data{1};
				fprintf('New params inserted with id = %d\n', paramID);
			else
				paramID = curs.Data{1};
				fprintf('Using existing parameter ID = %d\n', paramID);
			end
			close(curs);
			close(conn)
		end
		
		function [curs, colnames] = fetchSpecificParams(obj, conn, params)
			if strcmp(obj.systemType, 'PA')
				colnames = {'blockLength', 'absThresh', 'tolerance', 'note'};
				query = sprintf(['SELECT id FROM params WHERE', ' ', ...
					'blockLength = %d AND absThresh = %d AND tolerance = %d', ...
					' ','AND note="%s";'], ...
					params.blockLength, params.absThresh, params.tolerance, ...
					params.note);
			else
				if isnan(params.lockout)
					lockoutString = 'IS NULL';
				else
					lockoutString = sprintf('= %d',params.lockout);
				end
				if isnan(params.rwrdThreshold)
					rwrdString = 'IS NULL';
				else
					rwrdString = sprintf('= %d',params.rwrdThreshold);
				end
				if isnan(params.tolerance)
					toleranceString = 'IS NULL';
				else
					toleranceString = sprintf('= %d',params.tolerance);
				end
				
				colnames = {'rwrdThreshold','tolerance','width','maxRwrd', 'maxPen', ...
					'singleOccScore', 'missingScore', 'lockout', 'type', 'note'};
				query = sprintf(['SELECT id FROM params WHERE', ' ', ...
					'rwrdThreshold %s AND tolerance %s AND width = %d AND maxRwrd = %d', ...
					' ', 'AND maxPen = %d AND singleOccScore = %d AND', ...
					' ','missingScore = %d AND lockout %s AND type = "%s"', ...
					' ','AND note="%s";'], ...
					rwrdString, toleranceString, params.width, params.maxRwrd, ...
					params.maxPen, params.singleOccScore, ...
					params.missingScore, lockoutString, params.type, params.note);
			end
			curs = exec(conn, query);
			curs = fetch(curs);
		end
		
		function insertResults(obj, results, paramsID, resultNote)
			%INSERTRESULTS Inserts simulation results into the db
			%	First inserts the result summary into the 'results' table,
			%	before inserting the subresults into their respective
			%	tables.
			conn = database(obj.conf.datasource, obj.conf.username, ...
				obj.conf.password, obj.conf.driver, obj.conf.url);
			subResTables = {'pp', 'pm', 'mp', 'mm'};
			
			if strcmp(obj.systemType, 'PA')
				genRate = 'FNMR';
				impRate = 'FMR';
			else
				genRate = 'ANGA';
				impRate = 'ANIA';
			end
			colNames = {'params', 'numUsers', genRate, impRate, 'impND', 'note'};
			resultSummary = cell(1,6);
			resultSummary{1} = paramsID;
			resultSummary(2:5) = num2cell(results(5,:),1);
			resultSummary{6} = resultNote;
			insert(conn, 'results', colNames, resultSummary);
			% Insert subresults:
			colNames = colNames(2:5);
			for ii = 1:length(subResTables)
				insert(conn, subResTables{ii}, ...
					colNames, results(ii,:));
			end
			close(conn);
		end
	end
end

