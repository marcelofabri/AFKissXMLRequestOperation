// AFKissXMLRequestOperation.m
//
// Copyright (c) 2011 Gowalla (http://gowalla.com/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "AFKissXMLRequestOperation.h"
#import "AFKissXMLResponseSerializer.h"
#import "DDXML.h"

@interface AFKissXMLRequestOperation ()
@property (readwrite, nonatomic, strong) DDXMLDocument *responseXMLDocument;
@property (readwrite, nonatomic, strong) NSError *error;
@property (readwrite, nonatomic, strong) NSRecursiveLock *lock;
@end

@implementation AFKissXMLRequestOperation
@dynamic error;
@dynamic lock;

+ (instancetype)XMLDocumentRequestOperationWithRequest:(NSURLRequest *)urlRequest
                                               success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, DDXMLDocument *XMLDocument))success
                                               failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, DDXMLDocument *XMLDocument))failure {
    AFKissXMLRequestOperation *requestOperation = [(AFKissXMLRequestOperation *)[self alloc] initWithRequest:urlRequest];
    [requestOperation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (success) {
            success(operation.request, operation.response, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(operation.request, operation.response, error, [(AFKissXMLRequestOperation *)operation responseXMLDocument]);
        }
    }];
    
    return requestOperation;
    
}

- (instancetype)initWithRequest:(NSURLRequest *)urlRequest {
    self = [super initWithRequest:urlRequest];
    if (!self) {
        return nil;
    }
    
    self.responseSerializer = [AFKissXMLResponseSerializer serializer];
    
    return self;
}

#pragma mark AFJSONRequestOperation

- (DDXMLDocument *)responseXMLDocument {
    [self.lock lock];
    if (!_responseXMLDocument && [self.responseData length] > 0 && [self isFinished] && !self.error) {
        NSError *error = nil;
        self.responseXMLDocument = [self.responseSerializer responseObjectForResponse:self.response data:self.responseData error:&error];
        self.error = error;
    }
    [self.lock unlock];
    
    return _responseXMLDocument;
}

#pragma mark - AFHTTPRequestOperation

- (void)setCompletionBlockWithSuccess:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
                              failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure
{
    __weak __typeof(self)weakSelf = self;
    [super setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (![responseObject isKindOfClass:[NSData class]]) {
            strongSelf.responseXMLDocument = responseObject;
        }
        if (success) {
            success(operation, responseObject);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        strongSelf.error = error;
        if (failure) {
            failure(operation, error);
        }
    }];
}

@end
