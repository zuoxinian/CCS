import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np

import pdb 
import torch
import torch
import torch.nn.functional as F



def loss_design(label, representations):
    T = 0.5  # 温度参数T
    # label = torch.tensor([1, 0, 1, 0, 1])
    n = label.shape[0]  # batch

    # 假设我们的输入是5 * 3  5是batch，3是句向量
    # representations = torch.tensor([[1, 2, 3], [1.2, 2.2, 3.3],
    #                                 [1.3, 2.3, 4.3], [1.5, 2.6, 3.9],
    #                                 [5.1, 2.1, 3.4]])

    # 这步得到它的相似度矩阵
    similarity_matrix = F.cosine_similarity(representations.unsqueeze(1), representations.unsqueeze(0), dim=2)
    # 这步得到它的label矩阵，相同label的位置为1
    mask = torch.ones_like(similarity_matrix) * (label.expand(n, n).eq(label.expand(n, n).t()))

    # 这步得到它的不同类的矩阵，不同类的位置为1
    mask_no_sim = torch.ones_like(mask) - mask

    # 这步产生一个对角线全为0的，其他位置为1的矩阵
    mask_dui_jiao_0 = torch.ones(n, n).cuda() - torch.eye(n, n).cuda()

    # 这步给相似度矩阵求exp,并且除以温度参数T
    similarity_matrix = torch.exp(similarity_matrix / T)

    # 这步将相似度矩阵的对角线上的值全置0，因为对比损失不需要自己与自己的相似度
    similarity_matrix = similarity_matrix * mask_dui_jiao_0

    # 这步产生了相同类别的相似度矩阵，标签相同的位置保存它们的相似度，其他位置都是0，对角线上也为0
    sim = mask * similarity_matrix

    # 用原先的对角线为0的相似度矩阵减去相同类别的相似度矩阵就是不同类别的相似度矩阵
    no_sim = similarity_matrix - sim

    # 把不同类别的相似度矩阵按行求和，得到的是对比损失的分母(还差一个与分子相同的那个相似度，后面会加上)
    no_sim_sum = torch.sum(no_sim, dim=1)

    '''
    将上面的矩阵扩展一下，再转置，加到sim（也就是相同标签的矩阵上），然后再把sim矩阵与sim_num矩阵做除法。
    至于为什么这么做，就是因为对比损失的分母存在一个同类别的相似度，就是分子的数据。做了除法之后，就能得到
    每个标签相同的相似度与它不同标签的相似度的值，它们在一个矩阵（loss矩阵）中。
    '''
    no_sim_sum_expend = no_sim_sum.repeat(n, 1).T
    sim_sum = sim + no_sim_sum_expend
    loss = torch.div(sim, sim_sum)

    '''
    由于loss矩阵中，存在0数值，那么在求-log的时候会出错。这时候，我们就将loss矩阵里面为0的地方
    全部加上1，然后再去求loss矩阵的值，那么-log1 = 0 ，就是我们想要的。
    '''
    loss = mask_no_sim + loss + torch.eye(n, n).cuda()

    # 接下来就是算一个批次中的loss了
    loss = -torch.log(loss)  # 求-log
    loss = torch.sum(torch.sum(loss, dim=1)) / (2 * n)  # 将所有数据都加起来除以2n


    return  loss
def patch_size(x, patchsize):
    # x: [B, C, D, H, W]
    # patchsize: [k1, k2, k3]

    kc, kh, kw = patchsize  # kernel size
    dc, dh, dw = patchsize  # stride
    patches = x.unfold(2, kc, dc).unfold(3, kh, dh).unfold(4, kw, dw)
    # print(patches.shape)
    # unfold_shape = patches.size()
    patches = patches.contiguous().view(x.shape[0], x.shape[1], -1, kc, kh, kw)
    # print(patches.shape)
    # for i in range((patches.shape[2])):
    #     print(patches[0, :, i, :, :, :].shape)
    return patches

def ssm(pred, gt):
    # pred = torch.randn(1, 2, 32, 64, 80)
    # gt = torch.zeros(1, 1, 32, 64, 80)
    # gt[:, :, 12:16, 12:16, 12:16] = 1
    patchsize = [5, 5, 5]
    pred_patch = patch_size(pred, patchsize)
    gt = patch_size(gt, patchsize)

    loss = 0
    num =0
    for i in range((gt.shape[2])):
        label = gt[:, :, i, :, :].flatten(2)#.transpose(1, 2)
        pred = pred_patch[:, :, i, :, :].flatten(2)#.transpose(1, 2)

        if sum(label[label>0]) and sum(label[label>0]) < 125:
            # print(label.shape)
            label = label.squeeze(0).transpose(0, 1)
            pred = pred.squeeze(0).transpose(0, 1)

            loss += loss_design(label, pred)
            num += 1

    return loss / num

# print(ssm())

class DiceLoss(nn.Module):

    def __init__(self, alpha=0.5, beta=0.5, size_average=True, reduce=True):
        super(DiceLoss, self).__init__()
        self.alpha = alpha
        self.beta = beta

        self.size_average = size_average
        self.reduce = reduce

    def forward(self, preds, targets):
        # loss_ssm = ssm(preds, targets)
        # print(preds.shape, targets.shape)
        # print(preds.max(), targets.max())
        N = preds.size(0)
        C = preds.size(1)
        

        P = F.softmax(preds, dim=1)
        smooth = torch.zeros(C, dtype=torch.float32).fill_(0.00001)

        class_mask = torch.zeros(preds.shape).to(preds.device)
        class_mask.scatter_(1, targets, 1.) 

        ones = torch.ones(preds.shape).to(preds.device)
        P_ = ones - P 
        class_mask_ = ones - class_mask

        TP = P * class_mask
        FP = P * class_mask_
        FN = P_ * class_mask

        smooth = smooth.to(preds.device)
        self.alpha = FP.transpose(0, 1).reshape(C, -1).sum(dim=(1)) / ((FP.transpose(0, 1).reshape(C, -1).sum(dim=(1)) + FN.transpose(0, 1).reshape(C, -1).sum(dim=(1))) + smooth)
    
        self.alpha = torch.clamp(self.alpha, min=0.2, max=0.8) 
        #print('alpha:', self.alpha)
        self.beta = 1 - self.alpha
        num = torch.sum(TP.transpose(0, 1).reshape(C, -1), dim=(1)).float()
        den = num + self.alpha * torch.sum(FP.transpose(0, 1).reshape(C, -1), dim=(1)).float() + self.beta * torch.sum(FN.transpose(0, 1).reshape(C, -1), dim=(1)).float()

        dice = num / (den + smooth)

        if not self.reduce:
            loss = torch.ones(C).to(dice.device) - dice
            return loss

        loss = 1 - dice
        loss = loss.sum()

        if self.size_average:
            loss /= C

        # print(loss_ssm, loss)
        return loss # + loss_ssm /125

class FocalLoss(nn.Module):
    def __init__(self, class_num, alpha=None, gamma=2, size_average=True):
        super(FocalLoss, self).__init__()

        if alpha is None:
            self.alpha = torch.ones(class_num)
        else:
            self.alpha = alpha

        self.gamma = gamma
        self.size_average = size_average

    def forward(self, preds, targets):
        N = preds.size(0)
        C = preds.size(1)

        targets = targets.unsqueeze(1)
        P = F.softmax(preds, dim=1)
        log_P = F.log_softmax(preds, dim=1)

        class_mask = torch.zeros(preds.shape).to(preds.device)
        class_mask.scatter_(1, targets, 1.)
        
        if targets.size(1) == 1:
            # squeeze the chaneel for target
            targets = targets.squeeze(1)
        alpha = self.alpha[targets.data].to(preds.device)

        probs = (P * class_mask).sum(1)
        log_probs = (log_P * class_mask).sum(1)
        
        batch_loss = -alpha * (1-probs).pow(self.gamma)*log_probs

        if self.size_average:
            loss = batch_loss.mean()
        else:
            loss = batch_loss.sum()

        return loss

if __name__ == '__main__':
    
    DL = DiceLoss()
    FL = FocalLoss(10)
    
    pred = torch.randn(2, 10, 128, 128)
    target = torch.zeros((2, 1, 128, 128)).long()

    dl_loss = DL(pred, target)
    fl_loss = FL(pred, target)

    print('2D:', dl_loss.item(), fl_loss.item())

    pred = torch.randn(2, 10, 64, 128, 128)
    target = torch.zeros(2, 1, 64, 128, 128).long()

    dl_loss = DL(pred, target)
    fl_loss = FL(pred, target)

    print('3D:', dl_loss.item(), fl_loss.item())

    
