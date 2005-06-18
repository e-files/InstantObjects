unit TestInstantNumeric;

interface

uses fpcunit, InstantPersistence, InstantMock, TestModel;

type

  // Test methods for class TInstantNumeric
  TestTInstantNumeric = class(TTestCase)
  private
    FConn: TInstantMockConnector;
    FInstantNumeric: TInstantInteger;
    FOwner: TCompany;
  public
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestAsBoolean;
    procedure TestAsDateTime;
    procedure TestAsObject;
    procedure TestDisplayText;
    procedure TestIsDefault;
  end;

implementation

uses SysUtils, testregistry, InstantClasses;

procedure TestTInstantNumeric.SetUp;
begin
  FConn := TInstantMockConnector.Create(nil);
  FConn.BrokerClass := TInstantMockBroker;

  if InstantModel.ClassMetadatas.Count > 0 then
    InstantModel.ClassMetadatas.Clear;
  InstantModel.LoadFromResFile(ChangeFileExt(ParamStr(0), '.mdr'));

  FOwner := TCompany.Create(FConn);
  FInstantNumeric := FOwner._NoOfBranches;
end;

procedure TestTInstantNumeric.TearDown;
begin
  FInstantNumeric := nil;
  FreeAndNil(FOwner);
  InstantModel.ClassMetadatas.Clear;
  FreeAndNil(FConn);
end;

procedure TestTInstantNumeric.TestAsBoolean;
begin
  FInstantNumeric.AsBoolean := True;
  AssertEquals(1, FInstantNumeric.Value);
  AssertTrue(FInstantNumeric.AsBoolean);

  FInstantNumeric.AsBoolean := False;
  AssertEquals(0, FInstantNumeric.Value);
  AssertFalse(FInstantNumeric.AsBoolean);
end;

procedure TestTInstantNumeric.TestAsDateTime;
begin
  FInstantNumeric.AsDateTime := 12.45;
  AssertEquals(12, FInstantNumeric.Value);
  AssertEquals(12.0, FInstantNumeric.AsDateTime);
end;

procedure TestTInstantNumeric.TestAsObject;
var
  vObj: TInstantObject;
begin
  vObj := TInstantObject.Create(FConn);
  try
    try
      FInstantNumeric.AsObject := vObj;
      Fail('Exception was not thrown for Set AsObject!'); // should never get here
    except
      on E: EInstantAccessError do ; // do nothing as this is expected
      else
        raise;
    end;
  finally
    vObj.Free;
  end;

  try
    FInstantNumeric.AsObject;
    Fail('Exception was not thrown for Get AsObject!'); // should never get here
  except
    on E: EInstantAccessError do ; // do nothing as this is expected
    else
      raise;
  end;
end;

procedure TestTInstantNumeric.TestDisplayText;
begin
  FInstantNumeric.Value := 1;
  AssertEquals('1', FInstantNumeric.DisplayText);

  FInstantNumeric.Metadata.EditMask := '000';
  AssertEquals('001', FInstantNumeric.DisplayText);

  FInstantNumeric.Value := 1000;
  FInstantNumeric.Metadata.EditMask := '#,000'; //EditMask don't use ThousandSeparator var
  AssertEquals('1' + ThousandSeparator + '000', FInstantNumeric.DisplayText);
end;

procedure TestTInstantNumeric.TestIsDefault;
begin
  AssertTrue(FInstantNumeric.IsDefault);

  FInstantNumeric.Value := 100;
  AssertFalse(FInstantNumeric.IsDefault);
end;

initialization
  // Register any test cases with the test runner
{$IFNDEF CURR_TESTS}
  RegisterTests([TestTInstantNumeric]);
{$ENDIF}

end.
 