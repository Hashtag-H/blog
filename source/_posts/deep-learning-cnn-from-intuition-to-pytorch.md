---
title: "卷积神经网络：从直觉到 PyTorch 实现"
date: "2026-07-14"
updated: "2026-07-14"
categories: ["深度学习"]
tags: ["CNN", "深度学习", "训练技巧"]
description: "用图像识别的例子理解卷积、感受野、池化、通道与特征图，并给出一个可以继续扩展的 PyTorch 训练骨架。"
cover: "/images/generated/deep-learning-cnn-cover.png"
top_img: "/images/generated/deep-learning-cnn-cover.png"
sticky: 97
top: true
---
## 为什么 CNN 适合图像

图像不是一串互不相关的数字。相邻像素之间往往共享边缘、纹理、颜色过渡和空间结构。卷积神经网络的核心优势，就是把这种局部性变成可学习的参数：一个小卷积核在整张图上滑动，反复寻找相似的局部模式。

如果全连接网络直接处理一张 224 x 224 x 3 的图片，第一层就会产生巨量参数，而且它不知道“左上角的边缘”和“右下角的边缘”其实可以共享同一套识别方式。CNN 用局部连接和权重共享解决这个问题。

## 卷积核在学什么

可以把卷积核想象成一张小小的滤镜。浅层卷积核常常学习边缘、角点、颜色块；中层开始组合出纹理、局部形状；深层则更接近语义结构，比如眼睛、轮廓、车轮或者建筑边缘。

卷积层的输出叫特征图。一个通道对应一种检测器的响应强弱，多通道叠在一起，就像给图片做了一组可学习的观察笔记。
![image-20260722183601741](deep-learning-cnn-from-intuition-to-pytorch.assets/image-20260722183601741.png)

## 感受野与层级抽象

单个 3 x 3 卷积核只看很小一片区域，但多层堆叠后，后面的神经元能够间接看到更大的图像区域，这就是感受野逐渐扩大的过程。

这也是 CNN 的层级抽象能力来源：

1. 第一层看边缘。
2. 中间层看局部组合。
3. 后面层看更完整的结构。

这个过程很像人读图：先看到线条，再看到形状，最后理解对象。

## 池化不是必须，但很有用

池化层会降低空间分辨率，让特征更紧凑，也能带来一定的位置不敏感性。现在很多模型会用步幅卷积、全局平均池化等方式替代传统池化，但“逐步压缩空间、增强语义”的思想仍然保留着。

## 一个简洁的 PyTorch 骨架

```python
import torch
from torch import nn

class TinyCNN(nn.Module):
    def __init__(self, num_classes=10):
        super().__init__()
        self.features = nn.Sequential(
            nn.Conv2d(3, 32, kernel_size=3, padding=1),
            nn.BatchNorm2d(32),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
            nn.Conv2d(32, 64, kernel_size=3, padding=1),
            nn.BatchNorm2d(64),
            nn.ReLU(inplace=True),
            nn.MaxPool2d(2),
        )
        self.classifier = nn.Sequential(
            nn.AdaptiveAvgPool2d(1),
            nn.Flatten(),
            nn.Linear(64, num_classes),
        )

    def forward(self, x):
        x = self.features(x)
        return self.classifier(x)
```

这个模型不追求复杂，而是保留了 CNN 的几个关键部件：卷积、归一化、非线性、下采样和分类头。初学时先把每一层的输入输出尺寸打印出来，比直接背结构更有效。

## 调试建议

- 先在小数据集上过拟合几十张图片，确认模型有学习能力。
- 观察 loss 是否下降，准确率是否比随机猜测高。
- 检查输入归一化是否和预训练模型要求一致。
- 不要一开始就堆很深，先让一个小模型稳定跑通。

## 小结

CNN 的美感在于简单：小卷积核、权重共享、层级特征。理解它不需要先记住所有经典网络结构，先把“局部模式如何被反复发现和组合”想清楚，就已经走在正确的路上。
