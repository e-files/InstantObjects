(*
 *   InstantObjects
 *   InterBase Express Support
 *)

(* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is: Seleqt InstantObjects
 *
 * The Initial Developer of the Original Code is: Seleqt
 *
 * Portions created by the Initial Developer are Copyright (C) 2001-2003
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 * Carlo Barazzetta:
 * - blob streaming in XML format (Part, Parts, References)
 * - Prepared queries support
 * - OnLogin event support
 *
 * ***** END LICENSE BLOCK ***** *)

unit InstantIBX;

interface

uses
  Classes, Db, IBDatabase, IBTable, IBQuery, SysUtils, InstantPersistence,
  InstantClasses, InstantCommand;

type
  TIBXNetType = (ntLocal, ntTCP, ntNetBEUI, ntSPX);

  TInstantIBXOption = (ibxUseDelimitedIdents);
  TInstantIBXOptions = set of TInstantIBXOption;

const
  DefaultInstantIBXOptions = [ibxUseDelimitedIdents];

type
  TInstantIBXConnectionDef = class(TInstantConnectionBasedConnectionDef)
  private
    FPath: string;
    FServerName: string;
    FNetType: TIBXNetType;
    FOptions: TInstantIBXOptions;
    FParams: string; //CB
    function GetDatabaseName: string;
    function GetServerName: string;
  protected
    function CreateConnection(AOwner: TComponent): TCustomConnection; override;
    procedure InitConnector(Connector: TInstantConnector); override; //CB
  public
    class function ConnectionTypeName: string; override;
    class function ConnectorClass: TInstantConnectorClass; override;
    constructor Create(Collection: TCollection); override; //CB
    function Edit: Boolean; override;
    property DatabaseName: string read GetDatabaseName;
  published
    property Path: string read FPath write FPath;
    property NetType: TIBXNetType read FNetType write FNetType;
    property ServerName: string read GetServerName write FServerName;
    property Options: TInstantIBXOptions read FOptions write FOptions; //CB
    property Params: string read FParams write FParams; //CB
  end;

  TInstantIBXConnector = class(TInstantConnectionBasedConnector)
  private
    FTransaction: TIBTransaction;
    FOptions: TInstantIBXOptions;
    FOnLogin: TIBDatabaseLoginEvent;
    function GetConnection: TIBDatabase;
    function GetTransaction: TIBTransaction;
    procedure SetConnection(const Value: TIBDatabase);
  protected
    function CreateBroker: TInstantBroker; override;
    procedure InternalBuildDatabase(Scheme: TInstantScheme); override;
    procedure InternalCommitTransaction; override;
    procedure InternalRollbackTransaction; override;
    procedure InternalStartTransaction; override;
    procedure InternalCreateDatabase; override; //CB
    procedure AssignLoginOptions; override;//CB
  public
    constructor Create(AOwner: TComponent); override; //CB
    destructor Destroy; override;
    class function ConnectionDefClass: TInstantConnectionDefClass; override;
    property Transaction: TIBTransaction read GetTransaction;
  published
    property Connection: TIBDatabase read GetConnection write SetConnection;
    property Options: TInstantIBXOptions read FOptions write FOptions default DefaultInstantIBXOptions; //CB
    property OnLogin: TIBDatabaseLoginEvent read FOnLogin write FOnLogin; //CB
  end;

  TInstantIBXBroker= class(TInstantSQLBroker)
  private
    function GetDialect: Integer;
    function GetConnector: TInstantIBXConnector;
    function DelimitedIdentsEnabled: Boolean; //CB
  protected
    function CreateResolver(Map: TInstantAttributeMap): TInstantSQLResolver; override;
    function GetDatabaseName: string; override;
    function GetDBMSName: string; override;
    function GetSQLDelimiters: string; override;
    function GetSQLQuote: Char; override;
    function InternalCreateQuery: TInstantQuery; override;
    procedure PrepareQuery(DataSet : TDataSet); override; //CB
    procedure UnprepareQuery(DataSet : TDataSet); override; //CB
    function ExecuteQuery(DataSet : TDataSet) : integer; override; //CB
    procedure AssignDataSetParams(DataSet : TDataSet; AParams: TParams); override; //CB
  public
    function CreateDataSet(const AStatement: string; AParams: TParams = nil): TDataSet; override;
    function DataTypeToColumnType(DataType: TInstantDataType; Size: Integer): string; override;
    function Execute(const AStatement: string; AParams: TParams = nil): Integer; override;
    property Connector: TInstantIBXConnector read GetConnector;
    property Dialect: Integer read GetDialect;
  end;

  TInstantIBXResolver = class(TInstantSQLResolver)
  protected
    function ReadBooleanField(DataSet: TDataSet; const FieldName: string): Boolean; override;
  end;

  TInstantIBXTranslator = class(TInstantRelationalTranslator)
  protected
    function TranslateConstant(Constant: TInstantIQLConstant; Writer: TInstantIQLWriter): Boolean; override;
  end;

  TInstantIBXQuery = class(TInstantSQLQuery)
  protected
    class function TranslatorClass: TInstantRelationalTranslatorClass; override;
  end;

procedure Register;

implementation

uses
  Controls, InstantConsts, InstantIBXConnectionDefEdit, InstantUtils,
  IB, IBHeader, IBIntf;

procedure Register;
begin
  RegisterComponents('InstantObjects', [TInstantIBXConnector]);
end;

{ TInstantIBXConnectionDef }

class function TInstantIBXConnectionDef.ConnectionTypeName: string;
begin
  Result := 'IBX';
end;

class function TInstantIBXConnectionDef.ConnectorClass: TInstantConnectorClass;
begin
  Result := TInstantIBXConnector;
end;

constructor TInstantIBXConnectionDef.Create(Collection: TCollection);
begin
  inherited;
  FOptions := DefaultInstantIBXOptions;

end;

function TInstantIBXConnectionDef.CreateConnection(
  AOwner: TComponent): TCustomConnection;
var
  Connection: TIBDatabase;
begin
  Connection := TIBDatabase.Create(AOwner);
  try
    Connection.DatabaseName := DatabaseName;
    Connection.SQLDialect := 3; //CB
    Connection.Params.Text := Params; //CB
  except
    Connection.Free;
    raise;
  end;
  Result := Connection;
end;

function TInstantIBXConnectionDef.Edit: Boolean;
begin
  with TInstantIBXConnectionDefEditForm.Create(nil) do
  try
    LoadData(Self);
    Result := ShowModal = mrOk;
    if Result then
      SaveData(Self);
  finally
    Free;
  end;
end;

function TInstantIBXConnectionDef.GetDatabaseName: string;
var
  Fmt: string;
begin
  if NetType = ntLocal then
    Result := Path
  else begin
    case NetType of
      ntTCP: Fmt := '%s:%s';
      ntNetBEUI: Fmt := '\\%s\%s';
      ntSPX: Fmt := '%s@%s';
    end;
    Result := Format(Fmt, [ServerName, Path]);
  end;
end;

function TInstantIBXConnectionDef.GetServerName: string;
begin
  if NetType = ntLocal then
    Result := ''
  else
    Result := FServerName;
end;

procedure TInstantIBXConnectionDef.InitConnector(
  Connector: TInstantConnector);
begin
  inherited;
  (Connector as TInstantIBXConnector).Options := FOptions;
end;

{ TInstantIBXConnector }

procedure TInstantIBXConnector.AssignLoginOptions;
begin
  inherited;
  if HasConnection then
  begin
    if Assigned(FOnLogin) and not Assigned(Connection.OnLogin) then
      Connection.OnLogin := FOnLogin;
  end;
end;

class function TInstantIBXConnector.ConnectionDefClass: TInstantConnectionDefClass;
begin
  Result := TInstantIBXConnectionDef;
end;

constructor TInstantIBXConnector.Create(AOwner: TComponent);
begin
  inherited;
  FOptions := DefaultInstantIBXOptions;
end;

function TInstantIBXConnector.CreateBroker: TInstantBroker;
begin
  Result := TInstantIBXBroker.Create(Self);
end;

destructor TInstantIBXConnector.Destroy;
begin
  FTransaction.Free;
  inherited;
end;

function TInstantIBXConnector.GetConnection: TIBDatabase;
begin
  Result := inherited Connection as TIBDatabase;
end;

function TInstantIBXConnector.GetTransaction: TIBTransaction;
begin
  if not Assigned(FTransaction) then
  begin
    CheckConnection;
    FTransaction := TIBTransaction.Create(nil);
    try
      FTransaction.DefaultDatabase := Connection;
      FTransaction.Params.Add('read_committed');
    except
      FTransaction.Free;
      raise;
    end
  end;
  Result := FTransaction;
end;

procedure TInstantIBXConnector.InternalBuildDatabase(
  Scheme: TInstantScheme);
begin
  Scheme.BlobStreamFormat := BlobStreamFormat; //CB
  StartTransaction;
  try
    inherited;
    CommitTransaction;
  except
    RollbackTransaction;
    raise;
  end;
end;

procedure TInstantIBXConnector.InternalCommitTransaction;
begin
  Transaction.Commit;
end;

procedure TInstantIBXConnector.InternalCreateDatabase;
var
  db_handle: TISC_DB_HANDLE;
  tr_handle: TISC_TR_HANDLE;
begin
  inherited;
  // IBX's TIBDatabase.CreateDatabase is fatally flawed and so we have to
  // bypass it for the time being.
  with Connection do
  begin
    CheckInactive;
    db_handle := nil;
    tr_handle := nil;
    Call(
      isc_dsql_execute_immediate(StatusVector, @db_handle, @tr_handle, 0,
        PChar('create database ''' + DatabaseName + ''' user ''' + Params.Values['user_name'] + ''' password ''' +
              Params.Values['password'] + ''''), SQLDialect, nil),
      True);
    Disconnect;
  end;
end;

procedure TInstantIBXConnector.InternalRollbackTransaction;
begin
  Transaction.Rollback;
end;

procedure TInstantIBXConnector.InternalStartTransaction;
begin
  if not Transaction.InTransaction then
    Transaction.StartTransaction;
end;

procedure TInstantIBXConnector.SetConnection(const Value: TIBDatabase);
begin
  inherited Connection := Value;
end;

{ TInstantIBXBroker}

procedure TInstantIBXBroker.AssignDataSetParams(DataSet : TDataSet; AParams: TParams);
var
  I: Integer;
  TargetParams : TParams;
  SourceParam, TargetParam: TParam;
begin
  //don't call inherited!
  TargetParams := TIBQuery(DataSet).Params;
  for I := 0 to Pred(AParams.Count) do
  begin
    SourceParam := AParams[I];
    TargetParam := TargetParams.FindParam(SourceParam.Name);
    if Assigned(TargetParam) then
      case SourceParam.DataType of
        ftBoolean:
          TargetParam.AsInteger := Integer(SourceParam.AsBoolean);
      else
        TargetParam.Assign(SourceParam);
      end;
  end;
end;

function TInstantIBXBroker.CreateDataSet(const AStatement: string;
  AParams: TParams): TDataSet;
var
  Query: TIBQuery;
begin
  Query := TIBQuery.Create(nil);
  with Query do
  begin
    Database := Connector.Connection;
    Transaction := Connector.Transaction;
    SQL.Text := AStatement;
    if Assigned(AParams) then
      AssignDataSetParams(Query,AParams);
  end;
  Result := Query;
end;

function TInstantIBXBroker.CreateResolver(
  Map: TInstantAttributeMap): TInstantSQLResolver;
begin
  Result := TInstantIBXResolver.Create(Self, Map);
end;

function TInstantIBXBroker.DataTypeToColumnType(
  DataType: TInstantDataType; Size: Integer): string;
const
  Types: array[TInstantDataType] of string = (
    'INTEGER',
    'DOUBLE PRECISION',
    'DECIMAL(14,4)',
    'SMALLINT',
    'VARCHAR',
    'BLOB SUB_TYPE 1', //CB
    'TIMESTAMP',
    'BLOB');
begin
  Result := Types[DataType];
  if (DataType = dtString) and (Size > 0) then
    Result := Result + InstantEmbrace(IntToStr(Size), '()');
end;

function TInstantIBXBroker.DelimitedIdentsEnabled: Boolean;
begin
  Result := ibxUseDelimitedIdents in Connector.Options;
end;

function TInstantIBXBroker.Execute(const AStatement: string;
  AParams: TParams): Integer;
begin
  with CreateDataSet(AStatement, AParams) as TIBQuery do
  try
    ExecSQL;
    Result := RowsAffected;
  finally
    Free;
  end;
end;

function TInstantIBXBroker.ExecuteQuery(DataSet: TDataSet) : integer;
begin
  //don't call inherited!
  with TIBQuery(DataSet) do
  begin
    ExecSQL;
    Result := RowsAffected;
  end;
end;

function TInstantIBXBroker.GetConnector: TInstantIBXConnector;
begin
  Result := inherited Connector as TInstantIBXConnector;
end;

function TInstantIBXBroker.GetDatabaseName: string;
begin
  Result := Connector.Connection.DatabaseName;
end;

function TInstantIBXBroker.GetDBMSName: string;
begin
  Result := 'InterBase';
end;

function TInstantIBXBroker.GetDialect: Integer;
begin
  Result := Connector.Connection.SQLDialect;
end;

function TInstantIBXBroker.GetSQLDelimiters: string;
begin
  if (Dialect = 3) and DelimitedIdentsEnabled() then
    Result := '""'
  else
    Result := inherited GetSQLDelimiters;
end;

function TInstantIBXBroker.GetSQLQuote: Char;
begin
  Result := '''';
end;

function TInstantIBXBroker.InternalCreateQuery: TInstantQuery;
begin
  Result := TInstantIBXQuery.Create(Connector);
end;

procedure TInstantIBXBroker.PrepareQuery(DataSet: TDataSet);
begin
  inherited;
  TIBQuery(DataSet).Prepare;
end;

procedure TInstantIBXBroker.UnprepareQuery(DataSet: TDataSet);
begin
  inherited;
  TIBQuery(DataSet).Unprepare;
end;

{ TInstantIBXTranslator }

function TInstantIBXTranslator.TranslateConstant(
  Constant: TInstantIQLConstant; Writer: TInstantIQLWriter): Boolean;
begin
  if SameText(Constant.Value, InstantTrueString) then
  begin
    Writer.WriteChar('1');
    Result := True;
  end else if SameText(Constant.Value, InstantFalseString) then
  begin
    Writer.WriteChar('0');
    Result := True;
  end else
    Result := inherited TranslateConstant(Constant, Writer);
end;

{ TInstantIBXQuery }

class function TInstantIBXQuery.TranslatorClass: TInstantRelationalTranslatorClass;
begin
  Result := TInstantIBXTranslator;
end;

{ TInstantIBXResolver }

function TInstantIBXResolver.ReadBooleanField(DataSet: TDataSet;
  const FieldName: string): Boolean;
begin
  Result := Boolean(DataSet.FieldByName(FieldName).AsInteger);
end;

initialization
  RegisterClass(TInstantIBXConnectionDef);
  TInstantIBXConnector.RegisterClass;

finalization
  TInstantIBXConnector.UnregisterClass;

end.