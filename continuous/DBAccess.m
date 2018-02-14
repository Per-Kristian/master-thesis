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
			obj.datasource = 'perkrisn_simpsmd';
			obj.username = 'perkrisn';
			obj.pwd = FileIO.getPassword();
			obj.driver = 'com.mysql.jdbc.Driver';
			obj.url = 'jdbc:mysql://mysql.stud.ntnu.no:3306/perkrisn_simpsmd';
		end
		
		function paramID = insertParams(obj, params)
			%insertParams Inserts a set of parameters into the DB.
			%   Returns the ID of the inserted row.
			%	If identical parameters already exist, return the existing
			%	ID.
			
			conn = database(obj.datasource,obj.username,obj.pwd, ... 
				obj.driver,obj.url);
			colnames = {'rwrdThreshold','width','maxRwrd', 'maxPen', ...
				'singleOccScore', 'missingScore', 'lockout', 'type'};
			tablename = 'params';
			query = sprintf(['SELECT id FROM params WHERE', ' ', ...
				'rwrdThreshold = %d AND width = %d AND maxRwrd = %d', ...
				' ', 'AND maxPen = %d AND singleOccScore = %d AND', ...
				' ','missingScore = %d AND lockout = %d AND type = "%s";'], ...
				params.rwrdThreshold, params.width, params.maxRwrd, ...
				params.maxPen, params.singleOccScore, ...
				params.missingScore, params.lockout, params.type);
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

