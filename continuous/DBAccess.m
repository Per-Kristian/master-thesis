classdef DBAccess
	%DBACCESS Summary of this class goes here
	%   Detailed explanation goes here
	
	properties (SetAccess=private)
		datasource
		username
		driver
		url
		pwd
	end
	
	methods
		function obj = DBAccess()
			%DBACCESS Construct an instance of this class
			%   Detailed explanation goes here
			obj.datasource = '***REMOVED***_simpsmd';
			obj.username = '***REMOVED***';
			obj.pwd = FileIO.getPassword();
			obj.driver = '***REMOVED***';
			obj.url = 'jdbc:mysql://***REMOVED***:3306/***REMOVED***_simpsmd';
		end
		
		function paramID = insertParams(obj, params)
			%insertParams Inserts a set of parameters into the DB.
			%   Returns the ID of the inserted row.
			%	If identical parameters already exist, return the existing
			%	ID.
			if isnan(params.lockout)
				lockoutString = 'IS NULL';
			else
				lockoutString = sprintf('= %d',params.lockout);
			end
			conn = database(obj.datasource,obj.username,obj.pwd, ... 
				obj.driver,obj.url);
			colnames = {'rwrdThreshold','width','maxRwrd', 'maxPen', ...
				'singleOccScore', 'missingScore', 'lockout', 'type', 'note'};
			tablename = 'params';
			query = sprintf(['SELECT id FROM params WHERE', ' ', ...
				'rwrdThreshold = %d AND width = %d AND maxRwrd = %d', ...
				' ', 'AND maxPen = %d AND singleOccScore = %d AND', ...
				' ','missingScore = %d AND lockout %s AND type = "%s"', ...
				' ','AND note="%s";'], ...
				params.rwrdThreshold, params.width, params.maxRwrd, ...
				params.maxPen, params.singleOccScore, ...
				params.missingScore, lockoutString, params.type, params.note);
			curs = exec(conn, query);
			curs = fetch(curs);
			if ischar(curs.Data{1})
				% if the data is 'No Data', insert new params
				insert(conn,tablename,colnames,params);
				% Get ID of the inserted row.
				query = ('SELECT id from params WHERE ID = @@IDENTITY');
				curs = exec(conn, query);
				curs = fetch(curs);
				paramID = curs.Data{1};
			else
				paramID = curs.Data{1};
			end
			close(curs);
			close(conn)
		end
		
		function insertResults(obj, results, paramsID)
			%INSERTRESULTS Inserts simulation results into the db
			%	First inserts the result summary into the 'results' table,
			%	before inserting the subresults into their respective
			%	tables.
			conn = database(obj.datasource,obj.username,obj.pwd, ... 
				obj.driver,obj.url);
			subResTables = {'pp', 'pm', 'mp', 'mm'};
			colNames = {'params', 'numUsers', 'ANGA', 'ANIA', 'impND'};
			resultSummary = cell(1,5);
			resultSummary{1} = paramsID;
			resultSummary(2:5) = num2cell(results(5,:),1);
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

